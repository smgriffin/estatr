# Automatic pagination for getStatsData, with optional resumable checkpointing.
#
# e-Stat caps a single response at 100,000 records and reports the full match
# count (TOTAL_NUMBER) on page one. We fetch page one sequentially, then fan out
# the *remaining* pages by absolute offset concurrently (bounded by max_active)
# -- "parallel but polite". This is the key differentiator over estatapi, which
# leaves pagination to the user.
#
# When a checkpoint path is supplied, each page's rows are persisted keyed by
# their absolute offset, so a multi-million-row pull that dies partway through
# resumes by re-requesting only the missing offsets (a completed-offset manifest,
# NOT a single "last NEXT_KEY", which only fits the sequential fallback).

# Fetch a getStatsData query and return list(values = <data.table of VALUE rows>,
# meta_body = <page-1 body, carrying CLASS_INF / NOTE>).
#
# @param params Base query params (without limit/startPosition).
# @param pull_limit Max total rows to return, or NULL for all matching rows.
# @param start 1-based absolute offset of the first row to fetch.
# @param checkpoint Optional file path for a resumable checkpoint store.
collect_stats_data <- function(params, key = get_estat_key(),
                               pull_limit = NULL, start = 1L,
                               max_active = getOption("estatr.max_active", estat_default_max_active),
                               checkpoint = NULL, lang = getOption("estatr.lang", "E")) {
  page_size <- getOption("estatr.page_size", estat_max_records_per_call)
  if (!is.null(pull_limit)) page_size <- min(pull_limit, page_size)

  # Page one is always fetched: it carries TOTAL_NUMBER and the bundled metadata.
  # If English has no release for this table, fall back to Japanese here and use
  # that language for every subsequent page too.
  lang <- estat_lang(lang)
  fetch_page1 <- function(l) estat_perform(
    estat_request("getStatsData",
      params = c(params, list(limit = page_size, startPosition = start)), key = key, lang = l),
    "GET_STATS_DATA"
  )
  got <- try_with_lang_fallback(lang, fetch_page1)
  page1 <- got$result
  lang <- got$lang
  info <- dig(page1, "GET_STATS_DATA", "STATISTICAL_DATA", "RESULT_INF")
  total_matched <- as_count(dig(info, "TOTAL_NUMBER"))
  to <- as_count(dig(info, "TO_NUMBER"))
  next_key <- dig(info, "NEXT_KEY")

  target_last <- total_matched
  if (!is.null(pull_limit)) target_last <- min(target_last, start + pull_limit - 1L)

  # The offset->rows manifest, seeded from any existing checkpoint plus page one.
  store <- checkpoint_load(checkpoint)
  store[[as.character(start)]] <- values_from_bodies(list(page1))
  if (!is.null(checkpoint)) checkpoint_save(checkpoint, store)

  if (!is.null(next_key) && !is.na(to) && to < target_last) {
    offsets <- seq.int(to + 1L, target_last, by = page_size)
    pending <- offsets[!(as.character(offsets) %in% names(store))]

    # With a checkpoint, fetch in batches and persist after each, so a crash
    # loses at most one batch. Without one, a single bounded-parallel sweep.
    batches <- if (is.null(checkpoint)) list(pending) else split_batches(pending, max_active)
    for (batch in batches) {
      if (length(batch) == 0) next
      reqs <- lapply(batch, function(off) {
        this_size <- min(page_size, target_last - off + 1L)
        estat_request("getStatsData",
          params = c(params, list(limit = this_size, startPosition = off)), key = key, lang = lang)
      })
      bodies <- estat_fetch_bodies(reqs, envelope = "GET_STATS_DATA", max_active = max_active)
      for (i in seq_along(batch)) {
        store[[as.character(batch[i])]] <- values_from_bodies(list(bodies[[i]]))
      }
      if (!is.null(checkpoint)) checkpoint_save(checkpoint, store)
    }
  }

  # Assemble every page in ascending offset order, one bulk rbindlist.
  ordered <- as.character(sort(as.integer(names(store))))
  values <- data.table::rbindlist(store[ordered], fill = TRUE, use.names = TRUE)
  list(values = values, meta_body = page1)
}

# Pull the VALUE rows out of a set of page bodies into one data.table. VALUE rows
# are flat records, so the column-wise fast builder handles them (this is the hot
# path on large multi-page pulls).
values_from_bodies <- function(bodies) {
  records <- unlist(
    lapply(bodies, function(b) {
      as_record_list(dig(b, "GET_STATS_DATA", "STATISTICAL_DATA", "DATA_INF", "VALUE"))
    }),
    recursive = FALSE
  )
  flat_records_to_dt(records)
}

# Split a vector of offsets into batches of at most `size`.
split_batches <- function(x, size) {
  if (length(x) == 0) return(list())
  unname(split(x, ceiling(seq_along(x) / size)))
}

# Load a checkpoint store (named list: offset -> data.table). Empty list if the
# path is NULL or the file does not exist.
checkpoint_load <- function(checkpoint) {
  if (is.null(checkpoint) || !file.exists(checkpoint)) return(list())
  tryCatch(readRDS(checkpoint), error = function(e) list())
}

# Persist a checkpoint store atomically (temp file + rename).
checkpoint_save <- function(checkpoint, store) {
  dir <- dirname(checkpoint)
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  tmp <- paste0(checkpoint, ".tmp-", Sys.getpid())
  saveRDS(store, tmp)
  file.rename(tmp, checkpoint)
  invisible(checkpoint)
}

as_count <- function(x) suppressWarnings(as.integer(x))

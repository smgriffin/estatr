# Automatic pagination for getStatsData.
#
# e-Stat caps a single response at 100,000 records and reports the full match
# count (TOTAL_NUMBER) on page one. We use that to fetch page one sequentially,
# then fan out the *remaining* pages by absolute offset concurrently (bounded by
# max_active) — "parallel but polite". This is the key differentiator over
# estatapi, which leaves pagination to the user.

# Fetch all pages of a getStatsData query and return the list of response bodies
# (bodies[[1]] is page one, which also carries CLASS_INF/NOTE metadata).
#
# @param params Base query params (without limit/startPosition).
# @param pull_limit Max total rows to return, or NULL for all matching rows.
# @param start 1-based absolute offset of the first row to fetch.
estat_stats_data_bodies <- function(params, key = get_estat_key(),
                                    pull_limit = NULL, start = 1L,
                                    max_active = getOption("estatr.max_active", estat_default_max_active)) {
  # The hard API cap is 100,000/call; the option lets tests (and, rarely, users
  # on a flaky connection) shrink pages to exercise or ease pagination.
  page_size <- getOption("estatr.page_size", estat_max_records_per_call)
  if (!is.null(pull_limit)) page_size <- min(pull_limit, page_size)

  page1_req <- estat_request(
    "getStatsData",
    params = c(params, list(limit = page_size, startPosition = start)),
    key = key
  )
  page1 <- estat_perform(page1_req, "GET_STATS_DATA")

  info <- dig(page1, "GET_STATS_DATA", "STATISTICAL_DATA", "RESULT_INF")
  total_matched <- as_count(dig(info, "TOTAL_NUMBER"))
  to <- as_count(dig(info, "TO_NUMBER"))
  next_key <- dig(info, "NEXT_KEY")

  # How far do we actually need to read? The smaller of "all matching rows" and
  # the caller's requested cap.
  target_last <- total_matched
  if (!is.null(pull_limit)) target_last <- min(target_last, start + pull_limit - 1L)

  # Single page covers it.
  if (is.null(next_key) || is.na(to) || to >= target_last) {
    return(list(page1))
  }

  # Fan out the remaining pages by absolute offset.
  offsets <- seq.int(to + 1L, target_last, by = page_size)
  reqs <- lapply(offsets, function(off) {
    this_size <- min(page_size, target_last - off + 1L)
    estat_request(
      "getStatsData",
      params = c(params, list(limit = this_size, startPosition = off)),
      key = key
    )
  })

  rest <- estat_fetch_bodies(reqs, envelope = "GET_STATS_DATA", max_active = max_active)
  c(list(page1), rest)
}

# Pull the VALUE rows out of every page body and assemble them into one
# data.table in a single bulk rbindlist (never a row-wise loop).
values_from_bodies <- function(bodies) {
  records <- unlist(
    lapply(bodies, function(b) {
      as_record_list(dig(b, "GET_STATS_DATA", "STATISTICAL_DATA", "DATA_INF", "VALUE"))
    }),
    recursive = FALSE
  )
  records_to_dt(records)
}

as_count <- function(x) suppressWarnings(as.integer(x))

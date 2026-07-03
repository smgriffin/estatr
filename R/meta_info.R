# Low-level wrapper for the getMetaInfo endpoint, plus the shared parser that
# turns e-Stat's CLASS_INF block into per-axis lookup tables. The same parser is
# reused by get_estat() on the CLASS_INF that getStatsData bundles into its own
# response, so metadata decoding has exactly one implementation.

#' Retrieve classification metadata for an e-Stat table
#'
#' Wraps the e-Stat `getMetaInfo` endpoint. Returns the classification metadata
#' needed to decode a table's numeric codes into labels: one tibble per
#' classification axis (`tab`, `cat01`, ..., `area`, `time`), keyed by the axis
#' id, each with `code`, `name`, `level`, `unit`, and `parent` columns.
#'
#' @param statsDataId The table id whose metadata to fetch.
#' @param key e-Stat appId. Defaults to the stored key.
#' @param cache If `TRUE` (default), read/write the parsed metadata from the
#'   on-disk cache (see [estat_cache_dir()]); metadata rarely changes, so this
#'   avoids a network round-trip on repeat calls. Set `FALSE` to force a fetch.
#' @param cache_ttl Maximum age, in seconds, of a cached entry before it is
#'   refetched. Defaults to `options(estatr.cache_ttl)` or 30 days.
#' @return A named list of [tibbles][tibble::tibble], one per classification
#'   axis, plus a `table_info` attribute with the table's overall description.
#' @export
#' @examples
#' \dontrun{
#' meta <- estat_meta_info("0003217721")
#' meta$cat01 # labels for the first category axis
#' }
estat_meta_info <- function(statsDataId, key = get_estat_key(), cache = TRUE,
                            cache_ttl = getOption("estatr.cache_ttl", 30 * 24 * 3600)) {
  if (!rlang::is_string(statsDataId) || !nzchar(statsDataId)) {
    cli::cli_abort(
      "{.arg statsDataId} must be a single non-empty string.",
      class = "estat_error_invalid_arg"
    )
  }

  if (isTRUE(cache)) {
    hit <- cache_get(meta_cache_key(statsDataId), sub = "meta", ttl = cache_ttl)
    if (!is.null(hit)) return(hit)
  }

  tables <- memo_fetch_meta_tables(statsDataId, key)

  if (isTRUE(cache)) cache_set(meta_cache_key(statsDataId), tables, sub = "meta")
  tables
}

# The actual getMetaInfo fetch + parse. Memoised in-session in .onLoad so
# repeated ids within one session skip even the disk read.
fetch_meta_tables <- function(statsDataId, key = get_estat_key()) {
  req <- estat_request("getMetaInfo", params = list(statsDataId = statsDataId), key = key)
  body <- estat_perform(req, "GET_META_INFO")

  meta_inf <- dig(body, "GET_META_INFO", "METADATA_INF")
  tables <- class_inf_to_tables(dig(meta_inf, "CLASS_INF"))
  attr(tables, "table_info") <- flatten_record(dig(meta_inf, "TABLE_INF") %||% list())
  tables
}

# Convert a CLASS_INF block (from getMetaInfo or getStatsData) into a named list
# of per-axis tibbles. Each CLASS_OBJ axis becomes one tibble keyed by its @id.
class_inf_to_tables <- function(class_inf) {
  class_obj <- as_record_list(dig(class_inf, "CLASS_OBJ"))
  tables <- lapply(class_obj, function(axis) {
    dt <- records_to_dt(as_record_list(axis[["CLASS"]]))
    tibble::as_tibble(normalise_class_columns(dt))
  })
  names(tables) <- vapply(class_obj, function(axis) axis[["@id"]] %||% NA_character_, character(1))
  # Keep the axis display names alongside, for messaging and get_estat() columns.
  attr(tables, "axis_names") <- stats::setNames(
    vapply(class_obj, function(axis) axis[["@name"]] %||% NA_character_, character(1)),
    names(tables)
  )
  tables
}

# CLASS entries are {@code, @name, @level, @unit, @parentCode}. Normalise to
# stable, un-prefixed column names so downstream joins can rely on them.
normalise_class_columns <- function(dt) {
  if (nrow(dt) == 0) {
    return(data.table::data.table(
      code = character(), name = character(),
      level = character(), unit = character(), parent = character()
    ))
  }
  rename <- c(
    code = "code", name = "name", level = "level",
    unit = "unit", parentCode = "parent"
  )
  for (from in names(rename)) {
    to <- rename[[from]]
    if (from %in% names(dt) && !identical(from, to)) {
      data.table::setnames(dt, from, to)
    }
  }
  for (col in c("code", "name", "level", "unit", "parent")) {
    if (!col %in% names(dt)) dt[, (col) := NA_character_]
  }
  dt[]
}

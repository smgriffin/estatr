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
#' @return A named list of [tibbles][tibble::tibble], one per classification
#'   axis, plus a `table_info` attribute with the table's overall description.
#' @export
#' @examples
#' \dontrun{
#' meta <- estat_meta_info("0003217721")
#' meta$cat01 # labels for the first category axis
#' }
estat_meta_info <- function(statsDataId, key = get_estat_key()) {
  if (!rlang::is_string(statsDataId) || !nzchar(statsDataId)) {
    cli::cli_abort(
      "{.arg statsDataId} must be a single non-empty string.",
      class = "estat_error_invalid_arg"
    )
  }

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

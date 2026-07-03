# The high-level, tidycensus-style entry point: get_estat().
#
# It fetches data and metadata in a single getStatsData call (which bundles
# CLASS_INF), decodes e-Stat's numeric codes to labels via data.table binary
# joins, coerces values to numeric while preserving annotation markers in a
# separate flag column, and returns a tidy tibble at the boundary.

#' Get tidy, labelled data from e-Stat
#'
#' The main entry point. Given a `statsDataId`, fetches the data and its
#' classification metadata in one call, decodes every numeric code to a
#' human-readable label, and returns a tidy tibble: one row per observation with
#' paired label/code columns for each classification axis (e.g. `area` +
#' `area_code`, `time` + `time_code`), the `unit`, a numeric `value`, and an
#' `annotation` column preserving any non-numeric markers (suppressed cells,
#' footnote symbols) instead of silently coercing them to `NA`.
#'
#' @param statsDataId The table id to retrieve (from [estat_stats_list()] or
#'   [search_estat()]).
#' @param ... Filter parameters passed to `getStatsData` (e.g. `cdCat01`,
#'   `cdArea`, `cdTime`, `cdTimeFrom`, `cdTimeTo`).
#' @param decode_labels If `TRUE` (default), join metadata labels onto the coded
#'   values. `FALSE` skips the metadata join entirely and returns just the coded
#'   columns — a power-user fast path.
#' @param as_data_table If `TRUE`, return the internal `data.table` directly
#'   instead of converting to a tibble, for bulk-analysis users who don't want
#'   even the boundary conversion. Defaults to `FALSE`.
#' @param limit Maximum number of rows to return. `NULL` (default) returns all
#'   matching rows.
#' @param checkpoint Optional path to a checkpoint file for resumable pulls (see
#'   [estat_stats_data()]).
#' @param key e-Stat appId. Defaults to the stored key.
#' @return A tidy [tibble][tibble::tibble] (or `data.table` if `as_data_table`),
#'   with a `notes` attribute holding the table's annotation legend.
#' @export
#' @examples
#' \dontrun{
#' estat_api_key("your-app-id")
#' # Labour Force Survey, one category, decoded to labels
#' get_estat("0003217721", cdCat03 = "1", limit = 500)
#' }
get_estat <- function(statsDataId, ..., decode_labels = TRUE,
                      as_data_table = FALSE, limit = NULL,
                      checkpoint = NULL, key = get_estat_key()) {
  validate_stats_data_args(statsDataId, limit, 1L)

  params <- c(list(statsDataId = statsDataId), list(...))
  res <- collect_stats_data(params, key = key, pull_limit = limit, checkpoint = checkpoint)

  dt <- res$values
  notes <- notes_from_body(res$meta_body)

  # Split value into a numeric column and an annotation flag, rather than
  # coercing suppressed/footnoted cells silently to NA.
  dt <- split_value_annotation(dt)

  if (isTRUE(decode_labels) && nrow(dt) > 0) {
    class_inf <- dig(res$meta_body, "GET_STATS_DATA", "STATISTICAL_DATA", "CLASS_INF")
    tables <- class_inf_to_tables(class_inf)
    dt <- decode_axes(dt, tables)
  }

  data.table::setattr(dt, "notes", notes)
  if (isTRUE(as_data_table)) return(dt[])
  out <- tibble::as_tibble(dt)
  attr(out, "notes") <- notes
  out
}

# Coerce `value` to numeric; where that yields NA but the original string was
# non-empty (a marker like "-", "***", "X"), keep the original string in
# `annotation`. Leaves genuinely empty values as NA/NA.
split_value_annotation <- function(dt) {
  if (!"value" %in% names(dt) || nrow(dt) == 0) {
    dt[, annotation := character(0)]
    return(dt)
  }
  raw <- dt[["value"]]
  num <- suppressWarnings(as.numeric(raw))
  is_marker <- is.na(num) & !is.na(raw) & nzchar(raw)
  dt[, annotation := ifelse(is_marker, raw, NA_character_)]
  dt[, value := num]
  dt[]
}

# Join each classification axis's labels onto the coded columns via data.table
# binary joins. For axis "X": the coded column X becomes X_code, and a new X
# holds the decoded label.
decode_axes <- function(dt, tables) {
  axis_ids <- intersect(names(tables), names(dt))
  axis_labels <- attr(tables, "axis_names")

  for (axis in axis_ids) {
    lookup <- data.table::as.data.table(tables[[axis]])[, .(code, label = name)]
    code_col <- paste0(axis, "_code")
    data.table::setnames(dt, axis, code_col)
    dt <- merge(
      dt, lookup,
      by.x = code_col, by.y = "code",
      all.x = TRUE, sort = FALSE
    )
    data.table::setnames(dt, "label", axis)
    # Preserve the human axis name (e.g. "就業状態") as a column label.
    if (!is.null(axis_labels) && axis %in% names(axis_labels)) {
      data.table::setattr(dt[[axis]], "label", unname(axis_labels[[axis]]))
    }
  }

  data.table::setcolorder(dt, decoded_column_order(dt, axis_ids))
  dt[]
}

# Order columns for readability: geography and time first (label then code),
# then the remaining category axes, then unit / value / annotation.
decoded_column_order <- function(dt, axis_ids) {
  front <- character()
  for (axis in c("area", "time")) {
    if (axis %in% axis_ids) front <- c(front, axis, paste0(axis, "_code"))
  }
  cats <- setdiff(axis_ids, c("area", "time"))
  for (axis in cats) front <- c(front, axis, paste0(axis, "_code"))
  tail_cols <- intersect(c("unit", "value", "annotation"), names(dt))
  c(front, setdiff(names(dt), c(front, tail_cols)), tail_cols)
}

# Pull the annotation legend (NOTE) out of a getStatsData body into a small
# tibble mapping each marker character to its meaning.
notes_from_body <- function(body) {
  note <- as_record_list(dig(body, "GET_STATS_DATA", "STATISTICAL_DATA", "DATA_INF", "NOTE"))
  if (length(note) == 0) {
    return(tibble::tibble(char = character(), note = character()))
  }
  dt <- records_to_dt(note)
  # NOTE entries are {@char, $}: flatten_record maps "$" to "value".
  tibble::tibble(
    char = if ("char" %in% names(dt)) as.character(dt$char) else NA_character_,
    note = if ("value" %in% names(dt)) as.character(dt$value) else NA_character_
  )
}

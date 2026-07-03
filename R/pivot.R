# Wide-reshaping helper, mirroring tidycensus's output = "wide" without forcing
# it as the default. Implemented with data.table::dcast internally.

#' Pivot tidy e-Stat output to wide form
#'
#' Reshapes the long/tidy output of [get_estat()] into wide form, spreading the
#' labels of one classification axis across columns. Mirrors tidycensus's
#' `output = "wide"`, but as an explicit opt-in step rather than the default.
#'
#' @param data A tibble or data.frame from [get_estat()] (with `decode_labels`).
#' @param names_from Column whose values become the new column names (e.g.
#'   `"cat01"`). Its paired `_code` column is dropped from the id set.
#' @param values_from Column holding the cell values to spread. Defaults to
#'   `"value"`.
#' @param id_cols Columns identifying each output row. Defaults to every column
#'   except `names_from` (and its `_code` partner), `values_from`, and
#'   `annotation`.
#' @return A wide [tibble][tibble::tibble], one row per unique combination of
#'   `id_cols`.
#' @export
#' @examples
#' \dontrun{
#' d <- get_estat("0003217721", limit = 500)
#' pivot_estat_wide(d, names_from = "cat01")
#' }
pivot_estat_wide <- function(data, names_from, values_from = "value", id_cols = NULL) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame from {.fn get_estat}.")
  }
  if (!rlang::is_string(names_from) || !names_from %in% names(data)) {
    cli::cli_abort("{.arg names_from} must be a column name in {.arg data}.")
  }
  if (!values_from %in% names(data)) {
    cli::cli_abort("{.arg values_from} ({.val {values_from}}) is not a column in {.arg data}.")
  }

  dt <- data.table::as.data.table(data)

  drop <- c(names_from, paste0(names_from, "_code"), values_from, "annotation")
  if (is.null(id_cols)) {
    id_cols <- setdiff(names(dt), drop)
  } else {
    missing <- setdiff(id_cols, names(dt))
    if (length(missing)) {
      cli::cli_abort("Unknown {.arg id_cols}: {.val {missing}}.")
    }
  }

  if (length(id_cols) == 0) {
    # Nothing to key on: dcast against a constant so we still widen.
    dt[, ".__row__" := 1L]
    id_cols <- ".__row__"
  }

  formula <- stats::as.formula(
    paste(paste(sprintf("`%s`", id_cols), collapse = " + "), "~", sprintf("`%s`", names_from))
  )
  wide <- data.table::dcast(dt, formula, value.var = values_from)
  if (".__row__" %in% names(wide)) wide[, ".__row__" := NULL]
  tibble::as_tibble(wide)
}

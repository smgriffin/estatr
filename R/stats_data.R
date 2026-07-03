# Low-level wrapper for the getStatsData endpoint.

#' Retrieve statistical data values from e-Stat
#'
#' Low-level wrapper around the e-Stat `getStatsData` endpoint. Given a
#' `statsDataId` (from [estat_stats_list()]) and optional filter codes, returns a
#' tibble of the raw data values, one row per observation, with e-Stat's numeric
#' classification codes intact (`tab`, `cat01`, ..., `area`, `time`, `unit`,
#' `value`).
#'
#' Pagination is automatic: e-Stat caps each response at 100,000 records, and
#' this function fetches the remaining pages concurrently (bounded, throttled)
#' using the total record count reported on the first page. For decoded,
#' analysis-ready output with human-readable labels, use [get_estat()].
#'
#' @param statsDataId The table id to retrieve (a ~10-digit string).
#' @param ... Filter parameters passed to `getStatsData`, e.g. `cdCat01`,
#'   `cdArea`, `cdTime`, `cdTimeFrom`, `cdTimeTo`. Vectors are comma-joined into
#'   e-Stat's expected code-list form.
#' @param limit Maximum number of rows to return. `NULL` (default) returns all
#'   matching rows, paginating as needed.
#' @param start_position 1-based absolute row offset to start from.
#' @param checkpoint Optional path to a checkpoint file for resumable pulls. When
#'   set, each page's rows are persisted keyed by absolute offset, so an
#'   interrupted large pull resumes by re-requesting only the missing pages.
#' @param key e-Stat appId. Defaults to the stored key.
#' @return A [tibble][tibble::tibble] of coded data values.
#' @export
#' @examples
#' \dontrun{
#' estat_api_key("your-app-id")
#' estat_stats_data("0003217721", cdCat03 = "1", limit = 100)
#' }
estat_stats_data <- function(statsDataId, ..., limit = NULL,
                             start_position = 1L, checkpoint = NULL,
                             key = get_estat_key()) {
  validate_stats_data_args(statsDataId, limit, start_position)

  params <- c(list(statsDataId = statsDataId), list(...))
  res <- collect_stats_data(
    params,
    key = key,
    pull_limit = limit,
    start = as.integer(start_position),
    checkpoint = checkpoint
  )
  tibble::as_tibble(res$values)
}

validate_stats_data_args <- function(statsDataId, limit, start_position) {
  if (!rlang::is_string(statsDataId) || !nzchar(statsDataId)) {
    cli::cli_abort(
      "{.arg statsDataId} must be a single non-empty string.",
      class = "estat_error_invalid_arg"
    )
  }
  if (!grepl("^[0-9]+$", statsDataId)) {
    cli::cli_abort(
      "{.arg statsDataId} should be an all-digits table id (from {.fn estat_stats_list}).",
      class = "estat_error_invalid_arg"
    )
  }
  check_scalar_count(limit, "limit")
  check_scalar_count(start_position, "start_position")
  if (identical(as.integer(start_position), 0L)) {
    cli::cli_abort(
      "{.arg start_position} is 1-based; use 1 for the first row.",
      class = "estat_error_invalid_arg"
    )
  }
  invisible()
}

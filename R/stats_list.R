# Low-level wrapper for the getStatsList endpoint.

#' Search the e-Stat catalog for statistical tables
#'
#' Low-level wrapper around the e-Stat `getStatsList` endpoint. Searches the
#' government-wide statistics catalog and returns a tibble of matching tables,
#' one row per table, including the `id` (the `statsDataId` you will pass to
#' `estat_stats_data()` once that wrapper is implemented).
#'
#' This is a power-user function that mirrors the API closely. Higher-level,
#' friendlier search (`search_estat()`) is planned for a later milestone.
#'
#' @param searchWord Keyword(s) to search. Japanese is supported and encoded as
#'   UTF-8. Combine terms with `AND`/`OR` per the e-Stat API.
#' @param statsCode Government statistics code to filter by (5 or 8 digits).
#' @param surveyYears Survey period filter: `yyyy`, `yyyymm`, or
#'   `yyyymm-yyyymm`.
#' @param statsField Statistics field code (2 or 4 digits).
#' @param searchKind Data kind: `1` (statistics, default) or `2` (regional
#'   statistics / sub-datasets).
#' @param limit Maximum number of tables to return.
#' @param startPosition 1-based row offset to start from.
#' @param ... Further query parameters passed through to `getStatsList`
#'   verbatim (e.g. `updatedDate`, `openYears`).
#' @param key e-Stat appId. Defaults to the stored key.
#' @return A [tibble][tibble::tibble] with one row per matching table. Returns a
#'   zero-row tibble when the search matches nothing.
#' @export
#' @examples
#' \dontrun{
#' estat_api_key("your-app-id")
#' # Tables mentioning the Labour Force Survey
#' estat_stats_list(searchWord = "労働力調査")
#' }
estat_stats_list <- function(searchWord = NULL,
                             statsCode = NULL,
                             surveyYears = NULL,
                             statsField = NULL,
                             searchKind = NULL,
                             limit = NULL,
                             startPosition = NULL,
                             ...,
                             key = get_estat_key()) {
  params <- c(
    list(
      searchWord = searchWord,
      statsCode = statsCode,
      surveyYears = surveyYears,
      statsField = statsField,
      searchKind = searchKind,
      limit = limit,
      startPosition = startPosition
    ),
    list(...)
  )
  validate_stats_list_params(params)

  req <- estat_request("getStatsList", params = params, key = key)
  body <- estat_perform(req, envelope = "GET_STATS_LIST")

  table_inf <- dig(body, "GET_STATS_LIST", "DATALIST_INF", "TABLE_INF")
  dt <- records_to_dt(as_record_list(table_inf))

  tibble::as_tibble(dt)
}

# Validate arguments before touching the network so a bad call fails with a
# specific message, not a raw HTTP or e-Stat error two layers down.
validate_stats_list_params <- function(params) {
  if (!is.null(params$searchKind)) {
    rlang::arg_match0(
      as.character(params$searchKind),
      c("1", "2"),
      arg_nm = "searchKind"
    )
  }
  check_scalar_count(params$limit, "limit")
  check_scalar_count(params$startPosition, "startPosition")
  if (!is.null(params$statsCode) &&
      !grepl("^[0-9]{5}([0-9]{3})?$", as.character(params$statsCode))) {
    cli::cli_abort(
      "{.arg statsCode} must be a 5- or 8-digit code.",
      class = "estat_error_invalid_arg"
    )
  }
  invisible(params)
}

check_scalar_count <- function(x, arg) {
  if (is.null(x)) return(invisible())
  n <- suppressWarnings(as.integer(x))
  if (length(x) != 1 || is.na(n) || n < 0) {
    cli::cli_abort(
      "{.arg {arg}} must be a single non-negative whole number.",
      class = "estat_error_invalid_arg"
    )
  }
  invisible()
}

# Curated shortcut tables: the handful of tables most users want first, keyed by
# a friendly name so nobody has to hunt for a statsDataId by hand.

#' List the curated e-Stat shortcut tables
#'
#' Returns the built-in table of curated shortcuts used by [get_estat_curated()]
#' and the survey-specific helpers. Entries whose `statsDataId` is `NA` are
#' recognised names that have not yet been curated to a specific table.
#'
#' @return A [tibble][tibble::tibble] with `key`, `statsDataId`, `label_en`, and
#'   `label_ja` columns.
#' @export
#' @examples
#' estat_curated_tables()
estat_curated_tables <- function() {
  tibble::as_tibble(.estatr_curated)
}

#' Get a curated e-Stat table by name
#'
#' Fetches a curated table via [get_estat()] using a friendly `key` from
#' [estat_curated_tables()], so you don't need to know its `statsDataId`.
#'
#' @param key A curated table key, e.g. `"labour_force_survey"`.
#' @param ... Passed to [get_estat()] (filters, `limit`, `decode_labels`, ...).
#' @return The tidy tibble from [get_estat()].
#' @export
#' @examples
#' \dontrun{
#' get_estat_curated("labour_force_survey", limit = 500)
#' }
get_estat_curated <- function(key, ...) {
  id <- lookup_curated_id(key)
  get_estat(id, ...)
}

# Resolve a curated key to a statsDataId, with actionable errors for unknown or
# not-yet-curated keys.
lookup_curated_id <- function(key) {
  if (!rlang::is_string(key)) {
    cli::cli_abort("{.arg key} must be a single string.")
  }
  row <- .estatr_curated[.estatr_curated$key == key, , drop = FALSE]
  if (nrow(row) == 0) {
    cli::cli_abort(
      c(
        "Unknown curated table {.val {key}}.",
        "i" = "See {.run estatr::estat_curated_tables()} for available keys."
      ),
      class = "estat_error_unknown_curated"
    )
  }
  if (is.na(row$statsDataId[[1]])) {
    cli::cli_abort(
      c(
        "The curated table {.val {key}} is recognised but not yet curated to a specific statsDataId.",
        "i" = "Use {.fn search_estat} to find the table you want, or open an issue to help curate this one."
      ),
      class = "estat_error_uncurated"
    )
  }
  row$statsDataId[[1]]
}

#' Get the Labour Force Survey (basic tabulation)
#'
#' Convenience wrapper for the Labour Force Survey table of 15-and-over
#' population by labour-force status. Equivalent to
#' `get_estat_curated("labour_force_survey", ...)`.
#'
#' @inheritDotParams get_estat -statsDataId
#' @return The tidy tibble from [get_estat()].
#' @export
#' @examples
#' \dontrun{
#' get_labour_force_survey(limit = 500)
#' }
get_labour_force_survey <- function(...) {
  get_estat_curated("labour_force_survey", ...)
}

#' Get the Family Income and Expenditure Survey
#'
#' Convenience wrapper for the Family Income and Expenditure Survey (household
#' income and spending, two-or-more-person households). Equivalent to
#' `get_estat_curated("family_income_survey", ...)`.
#'
#' @inheritDotParams get_estat -statsDataId
#' @return The tidy tibble from [get_estat()].
#' @export
#' @examples
#' \dontrun{
#' get_family_income_survey(limit = 500)
#' }
get_family_income_survey <- function(...) {
  get_estat_curated("family_income_survey", ...)
}

#' Get the Population Census (population by sex)
#'
#' Convenience wrapper for the 2020 Population Census table of population by sex
#' at national, prefecture, and municipality level. Equivalent to
#' `get_estat_curated("population_census", ...)`.
#'
#' @inheritDotParams get_estat -statsDataId
#' @return The tidy tibble from [get_estat()].
#' @export
#' @examples
#' \dontrun{
#' get_population_census(cdArea = "13000") # Tokyo
#' }
get_population_census <- function(...) {
  get_estat_curated("population_census", ...)
}

#' Get the Economic Census (establishments by industry)
#'
#' Convenience wrapper for the 2021 Economic Census (activity survey) table of
#' establishment counts by industry. Equivalent to
#' `get_estat_curated("economic_census", ...)`.
#'
#' @inheritDotParams get_estat -statsDataId
#' @return The tidy tibble from [get_estat()].
#' @export
#' @examples
#' \dontrun{
#' get_economic_census(limit = 500)
#' }
get_economic_census <- function(...) {
  get_estat_curated("economic_census", ...)
}

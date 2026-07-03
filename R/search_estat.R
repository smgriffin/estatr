# Friendlier discovery layer over getStatsList.

# The most useful columns for interactive browsing, mapped from e-Stat's raw
# getStatsList fields to stable snake_case names. Any that are absent from a
# given response are simply skipped.
search_estat_columns <- c(
  id = "id",
  stat_name = "STAT_NAME",
  statistics_name = "STATISTICS_NAME",
  title = "TITLE",
  gov_org = "GOV_ORG",
  survey_date = "SURVEY_DATE",
  cycle = "CYCLE",
  open_date = "OPEN_DATE",
  updated_date = "UPDATED_DATE"
)

#' Search the e-Stat catalog (interactive-friendly)
#'
#' A friendlier wrapper over [estat_stats_list()] for finding tables
#' interactively. Returns a tibble with the most useful columns renamed to
#' stable snake_case (`id`, `stat_name`, `title`, `gov_org`, `survey_date`, ...)
#' and moved to the front, with the raw columns kept after them.
#'
#' @param keyword Keyword(s) to search for. Japanese is supported. Combine terms
#'   with `AND`/`OR` per the e-Stat API.
#' @param gov_org Government organisation code to filter by (passed as
#'   `statsCode`'s org prefix is not assumed; use [estat_stats_list()] for full
#'   control).
#' @param updated_from,updated_to Optional update-date bounds (`yyyymmdd` or
#'   `yyyymm`) to restrict to recently refreshed tables.
#' @param limit Maximum number of tables to return (default 100).
#' @param ... Further parameters passed through to [estat_stats_list()].
#' @param key e-Stat appId. Defaults to the stored key.
#' @return A [tibble][tibble::tibble] of matching tables, friendly columns first.
#' @export
#' @examples
#' \dontrun{
#' search_estat("労働力調査")
#' search_estat("国勢調査", updated_from = "2020")
#' }
search_estat <- function(keyword = NULL, gov_org = NULL,
                         updated_from = NULL, updated_to = NULL,
                         limit = 100L, ..., key = get_estat_key()) {
  updated <- collapse_date_range(updated_from, updated_to)
  raw <- estat_stats_list(
    searchWord = keyword,
    limit = limit,
    updatedDate = updated,
    ...,
    key = key
  )
  reorder_search_columns(raw)
}

# Move the friendly, renamed columns to the front; keep everything else after.
reorder_search_columns <- function(raw) {
  if (nrow(raw) == 0 && ncol(raw) == 0) return(raw)
  present <- search_estat_columns[search_estat_columns %in% names(raw)]
  renamed <- raw
  for (i in seq_along(present)) {
    new <- names(present)[i]
    old <- present[[i]]
    if (!identical(new, old)) names(renamed)[names(renamed) == old] <- new
  }
  front <- names(present)
  tibble::as_tibble(renamed[, c(front, setdiff(names(renamed), front)), drop = FALSE])
}

# e-Stat expects an update-date filter as a single value or "from-to" range.
collapse_date_range <- function(from, to) {
  if (is.null(from) && is.null(to)) return(NULL)
  if (is.null(to)) return(from)
  if (is.null(from)) return(to)
  paste0(from, "-", to)
}

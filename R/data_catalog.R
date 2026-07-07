# Low-level wrapper for the getDataCatalog endpoint.
#
# getDataCatalog returns dataset/file catalog entries (Excel/CSV/PDF resource
# URLs) rather than machine-readable data. It is lower priority than the other
# three endpoints; this wrapper returns a flattened tibble of catalog entries so
# users can discover downloadable resources.

#' Search the e-Stat data catalog for datasets and files
#'
#' Wraps the e-Stat `getDataCatalog` endpoint, which returns catalog entries —
#' datasets and their downloadable resources (Excel/CSV/PDF URLs) — rather than
#' machine-readable data values. Use [estat_stats_data()] / [get_estat()] for the
#' actual numbers.
#'
#' @param searchWord Keyword(s) to search. Japanese is supported.
#' @param ... Further query parameters passed to `getDataCatalog` verbatim
#'   (e.g. `statsCode`, `dataType`, `limit`, `startPosition`).
#' @inheritParams get_estat
#' @param key e-Stat appId. Defaults to the stored key.
#' @return A [tibble][tibble::tibble] of catalog entries, one row per entry.
#'   Returns a zero-row tibble when nothing matches.
#' @export
#' @examples
#' \dontrun{
#' estat_data_catalog(searchWord = "国勢調査", limit = 10)
#' }
estat_data_catalog <- function(searchWord = NULL, ...,
                               lang = getOption("estatr.lang", "E"),
                               key = get_estat_key()) {
  params <- compact(c(list(searchWord = searchWord), list(...)))
  req <- estat_request("getDataCatalog", params = params, key = key, lang = lang)
  body <- estat_perform(req, "GET_DATA_CATALOG")

  entries <- as_record_list(
    dig(body, "GET_DATA_CATALOG", "DATA_CATALOG_LIST_INF", "DATA_CATALOG_INF")
  )
  tibble::as_tibble(records_to_dt(entries))
}

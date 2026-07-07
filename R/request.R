# Internal HTTP request builder for the e-Stat API.
#
# Everything that talks to e-Stat goes through `estat_request()`, so the
# cross-cutting concerns — appId injection, UTF-8 query encoding, JSON-by-default,
# gzip, transient-only retry, and client-side throttling — live in exactly one
# place.

#' Build an httr2 request for an e-Stat endpoint
#'
#' @param endpoint e-Stat endpoint name, e.g. `"getStatsList"`.
#' @param params Named list of query parameters. `NULL` elements are dropped.
#'   Values are URL-encoded as UTF-8 (needed for Japanese search terms).
#' @param key The appId. Defaults to the stored key; validated here so a missing
#'   key fails with a clear message before any network call.
#' @param throttle Minimum seconds between requests.
#' @return An `httr2_request` object, not yet performed.
#' @noRd
estat_request <- function(endpoint,
                          params = list(),
                          key = get_estat_key(),
                          throttle = getOption("estatr.throttle", estat_default_throttle),
                          lang = getOption("estatr.lang", "E")) {
  if (!nzchar(key %||% "")) {
    cli::cli_abort(
      c(
        "No e-Stat API key found.",
        "i" = "Register one with {.run estatr::estat_api_key()} or set the {.envvar {estat_key_envvar}} environment variable."
      ),
      class = "estat_error_no_key"
    )
  }

  # JSON endpoints live under /rest/<version>/app/json/<endpoint>.
  req <- httr2::request(estat_base_url())
  req <- httr2::req_url_path_append(
    req, "rest", estat_api_version(), "app", "json", endpoint
  )

  # appId and language first, then user params. Drop NULLs so optional args can
  # be passed through unconditionally. httr2 URL-encodes values as UTF-8 via curl.
  query <- c(
    stats::setNames(list(key), estat_appid_param),
    list(lang = estat_lang(lang)),
    compact(params)
  )
  req <- inject_query(req, query)

  req <- httr2::req_user_agent(req, estat_user_agent())

  # Ask for gzip explicitly; curl usually negotiates it, but on large tables it
  # matters enough to not leave to chance.
  req <- httr2::req_headers(req, `Accept-Encoding` = "gzip")

  # Retry transient failures only. e-Stat parameter errors come back as HTTP 200
  # with a non-zero RESULT.STATUS, so they never reach this path; genuine 4xx are
  # not retried (retrying a malformed request just hides the bug).
  req <- httr2::req_retry(
    req,
    max_tries = 3,
    is_transient = estat_is_transient,
    backoff = function(attempt) min(2^attempt, 30)
  )

  # Client-side throttle: minimum spacing between calls, shared across the
  # session by realm (host).
  if (!is.null(throttle) && throttle > 0) {
    req <- httr2::req_throttle(req, rate = 1 / throttle)
  }

  req <- httr2::req_timeout(req, getOption("estatr.timeout", 60))
  req
}

# Attach query parameters, keeping multi-value vectors intact.
inject_query <- function(req, query) {
  for (nm in names(query)) {
    value <- query[[nm]]
    if (is.null(value)) next
    # Collapse vectors the way e-Stat expects: comma-separated code lists.
    if (length(value) > 1) value <- paste(value, collapse = ",")
    req <- httr2::req_url_query(req, !!nm := value)
  }
  req
}

# Treat 5xx, 429, and low-level connection failures as transient. Everything
# else (notably 4xx) is a real error we should surface, not retry.
estat_is_transient <- function(resp) {
  status <- httr2::resp_status(resp)
  status == 429 || status >= 500
}

estat_user_agent <- function() {
  ver <- tryCatch(
    as.character(utils::packageVersion("estatr")),
    error = function(e) "dev"
  )
  paste0("estatr/", ver, " (https://github.com/smgriffin/estatr)")
}

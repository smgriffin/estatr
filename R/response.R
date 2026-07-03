# Central response handler for the e-Stat API.
#
# e-Stat returns HTTP 200 even for application-level failures, carrying the real
# outcome in a RESULT block (STATUS + ERROR_MSG). This layer treats RESULT.STATUS
# as the source of truth, maps it to classed R conditions so callers can
# tryCatch() on specifics, and scrubs the appId from anything it surfaces.

# Perform a request and return the parsed, validated JSON body (a list). The
# top-level e-Stat envelope key (e.g. "GET_STATS_LIST") is passed so we can reach
# into the right sub-object defensively.
#
# @param req An httr2 request from estat_request().
# @param envelope The expected top-level response key.
# @return The parsed response body as a list, guaranteed to have a RESULT with
#   STATUS == 0.
estat_perform <- function(req, envelope) {
  resp <- tryCatch(
    httr2::req_perform(req),
    httr2_http = function(cnd) {
      # Genuine HTTP-level failure (4xx/5xx that survived retry). Re-raise with a
      # scrubbed message and our own class.
      cli::cli_abort(
        "e-Stat request failed: {redact_appid(conditionMessage(cnd))}",
        class = c("estat_http_error", "estat_error"),
        parent = cnd
      )
    }
  )

  body <- parse_estat_body(resp)
  result <- dig(body, envelope, "RESULT")
  check_estat_status(result)
  body
}

# Parse the response body explicitly as UTF-8 JSON. e-Stat mixes Japanese and
# English and some legacy tables carry non-ASCII artifacts, so we never rely on
# the platform default encoding.
parse_estat_body <- function(resp) {
  text <- httr2::resp_body_string(resp, encoding = "UTF-8")
  body <- tryCatch(
    jsonlite::fromJSON(text, simplifyVector = FALSE),
    error = function(e) {
      cli::cli_abort(
        c(
          "Could not parse the e-Stat response as JSON.",
          "i" = "This usually means an unexpected response shape from e-Stat. Please file an issue."
        ),
        class = c("estat_parse_error", "estat_error"),
        parent = e
      )
    }
  )
  body
}

# Inspect RESULT.STATUS and raise a classed condition on failure. STATUS == 0 is
# success; everything else is an application error whose specific class is keyed
# off the documented status ranges.
check_estat_status <- function(result) {
  status <- suppressWarnings(as.integer(dig(result, "STATUS")))
  if (length(status) != 1 || is.na(status)) {
    cli::cli_abort(
      c(
        "Unexpected response shape from e-Stat: missing or malformed {.field RESULT.STATUS}.",
        "i" = "Please file an issue with the (redacted) request that triggered this."
      ),
      class = c("estat_parse_error", "estat_error")
    )
  }
  if (status == 0L) {
    return(invisible(result))
  }

  msg <- dig(result, "ERROR_MSG") %||% "(no error message returned)"
  msg <- redact_appid(as.character(msg))

  cli::cli_abort(
    c(
      "e-Stat API error (status {status}): {msg}"
    ),
    class = c(estat_status_class(status), "estat_api_error", "estat_error"),
    estat_status = status,
    estat_message = msg
  )
}

# Map an e-Stat status code to a specific condition subclass. e-Stat groups its
# error codes by hundreds; we key off the range so callers get a stable,
# meaningful class even before every individual code is catalogued from fixtures.
# Refine with exact codes as real error fixtures are recorded (M2).
estat_status_class <- function(status) {
  band <- switch(
    as.character(status %/% 100L),
    "1" = "estat_error_invalid_param",
    "2" = "estat_error_no_data",
    "3" = "estat_error_auth",
    "5" = "estat_error_server",
    "estat_error_other"
  )
  band
}

# Defensive nested-list accessor: dig(x, "A", "B") returns x[["A"]][["B"]] or
# NULL if any level is missing, instead of a cryptic subscript error.
dig <- function(x, ...) {
  keys <- c(...)
  for (k in keys) {
    if (!is.list(x) || is.null(x[[k]])) return(NULL)
    x <- x[[k]]
  }
  x
}

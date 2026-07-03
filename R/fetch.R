# Parallel fetch seam.
#
# This is the single internal chokepoint through which *sets* of requests are
# performed. It exists as its own function for two reasons:
#   1. Bounded-concurrency "parallel but polite" page fan-out lives in one place.
#   2. httr2's req_perform_parallel() does NOT honour local_mocked_responses
#      (verified against httr2 1.1.1), so tests mock THIS function via
#      testthat::local_mocked_bindings() rather than the HTTP layer.

# Perform several requests concurrently and return a list of parsed, validated
# response bodies in the same order. Each request already carries transient-only
# retry and the client-side throttle from estat_request(); max_active caps how
# many are in flight at once so we never hammer the government host.
estat_fetch_bodies <- function(reqs, envelope,
                               max_active = getOption("estatr.max_active", estat_default_max_active)) {
  resps <- httr2::req_perform_parallel(
    reqs,
    max_active = max_active,
    on_error = "return"
  )
  lapply(resps, function(resp) {
    if (inherits(resp, "error") || inherits(resp, "condition")) {
      cli::cli_abort(
        "e-Stat request failed during parallel fetch: {redact_appid(conditionMessage(resp))}",
        class = c("estat_http_error", "estat_error"),
        parent = if (inherits(resp, "condition")) resp else NULL
      )
    }
    body <- parse_estat_body(resp)
    check_estat_status(dig(body, envelope, "RESULT"))
    body
  })
}

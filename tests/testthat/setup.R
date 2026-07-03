# A dummy key so request-building tests don't hit the "no key" guard. Never a
# real appId. withr resets it after the test run.
withr::local_envvar(ESTAT_API_KEY = "test-app-id", .local_envir = teardown_env())

# Keep the whole test run out of the user's real cache directory.
withr::local_options(
  estatr.cache_dir = file.path(tempdir(), "estatr-cache-tests"),
  .local_envir = teardown_env()
)

# When (later) recording real fixtures with httptest2, scrub the appId out of the
# saved request URL/paths so a secret can never land in a committed fixture.
if (requireNamespace("httptest2", quietly = TRUE)) {
  httptest2::set_redactor(function(response) {
    response <- httptest2::gsub_response(response, "appId=[^&]+", "appId=REDACTED")
    response
  })
}

# Build a fake httr2 response carrying a JSON body, for offline end-to-end tests
# of the request -> response -> tibble pipeline via httr2::local_mocked_responses.
fake_json_response <- function(body, status = 200L) {
  httr2::response(
    status_code = status,
    url = "https://api.e-stat.go.jp/rest/3.0/app/json/getStatsList",
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(enc2utf8(body))
  )
}

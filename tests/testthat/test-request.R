test_that("estat_request builds a JSON-endpoint URL with appId and params", {
  req <- estat_request(
    "getStatsList",
    params = list(searchWord = "labour", limit = 5),
    key = "KEY123"
  )
  expect_s3_class(req, "httr2_request")
  expect_match(req$url, "/rest/3.0/app/json/getStatsList")
  expect_match(req$url, "appId=KEY123")
  expect_match(req$url, "searchWord=labour")
  expect_match(req$url, "limit=5")
})

test_that("NULL params are dropped from the query", {
  req <- estat_request(
    "getStatsList",
    params = list(searchWord = "x", statsCode = NULL),
    key = "K"
  )
  expect_no_match(req$url, "statsCode")
})

test_that("UTF-8 (Japanese) search terms are percent-encoded", {
  req <- estat_request("getStatsList", params = list(searchWord = "労働力"), key = "K")
  # Encoded, not raw multibyte, in the URL.
  expect_no_match(req$url, "労働力")
  expect_match(req$url, "%E5%8A%B4%E5%83%8D%E5%8A%9B")
})

test_that("vector code lists are comma-joined", {
  req <- estat_request("getStatsData", params = list(cdArea = c("01000", "02000")), key = "K")
  expect_match(req$url, "cdArea=01000%2C02000|cdArea=01000,02000")
})

test_that("missing key aborts before any network call", {
  expect_error(
    estat_request("getStatsList", params = list(), key = ""),
    class = "estat_error_no_key"
  )
})

test_that("only 429/5xx are treated as transient", {
  mk <- function(code) httr2::response(status_code = code)
  expect_true(estat_is_transient(mk(429)))
  expect_true(estat_is_transient(mk(503)))
  expect_true(estat_is_transient(mk(500)))
  expect_false(estat_is_transient(mk(400)))
  expect_false(estat_is_transient(mk(404)))
})

test_that("redact_appid hides the key in URLs and messages", {
  url <- "https://api.e-stat.go.jp/x?appId=SECRET&searchWord=y"
  expect_equal(redact_appid(url), "https://api.e-stat.go.jp/x?appId=<hidden>&searchWord=y")
  expect_no_match(redact_appid("appId=SECRET"), "SECRET")
})

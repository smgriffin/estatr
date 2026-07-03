test_that("STATUS 0 passes and the body is returned", {
  body <- list(GET_STATS_LIST = list(RESULT = list(STATUS = 0L, ERROR_MSG = "")))
  expect_silent(check_estat_status(body$GET_STATS_LIST$RESULT))
})

test_that("non-zero STATUS raises a classed estat_api_error with code and message", {
  result <- list(STATUS = 100L, ERROR_MSG = "invalid parameter")
  err <- expect_error(check_estat_status(result), class = "estat_error_invalid_param")
  expect_s3_class(err, "estat_api_error")
  expect_equal(err$estat_status, 100L)
  expect_match(conditionMessage(err), "invalid parameter")
})

test_that("status code bands map to distinct condition classes", {
  expect_error(check_estat_status(list(STATUS = 100)), class = "estat_error_invalid_param")
  expect_error(check_estat_status(list(STATUS = 200)), class = "estat_error_no_data")
  expect_error(check_estat_status(list(STATUS = 300)), class = "estat_error_auth")
  expect_error(check_estat_status(list(STATUS = 500)), class = "estat_error_server")
  expect_error(check_estat_status(list(STATUS = 999)), class = "estat_error_other")
})

test_that("the appId is scrubbed from error messages", {
  result <- list(STATUS = 100L, ERROR_MSG = "bad request for appId=SUPERSECRET")
  err <- expect_error(check_estat_status(result), class = "estat_api_error")
  expect_no_match(conditionMessage(err), "SUPERSECRET")
  expect_match(conditionMessage(err), "appId=<hidden>")
})

test_that("missing or malformed STATUS is a parse error, not a subscript error", {
  expect_error(check_estat_status(list()), class = "estat_parse_error")
  expect_error(check_estat_status(list(STATUS = "not-a-number")), class = "estat_parse_error")
})

test_that("dig() returns NULL for missing paths instead of erroring", {
  x <- list(A = list(B = 1))
  expect_equal(dig(x, "A", "B"), 1)
  expect_null(dig(x, "A", "C"))
  expect_null(dig(x, "Z"))
})

test_that("non-JSON bodies raise an estat_parse_error", {
  resp <- httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw("<html>not json</html>")
  )
  expect_error(parse_estat_body(resp), class = "estat_parse_error")
})

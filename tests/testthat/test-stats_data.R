test_that("estat_stats_data returns a coded tibble for a single page", {
  json <- sd_json(list(sd_value("11077"), sd_value("11079", time = "2018000406")),
                  total = 2, to = 2)
  httr2::local_mocked_responses(function(req) fake_json_response(json))

  d <- estat_stats_data("0003217721", limit = 2)
  expect_s3_class(d, "tbl_df")
  expect_equal(nrow(d), 2L)
  expect_true(all(c("tab", "cat01", "area", "time", "unit", "value") %in% names(d)))
  expect_equal(d$value, c("11077", "11079"))
})

test_that("pagination fans out remaining pages and concatenates in order", {
  # Page 1 (sequential, httr2-mocked): 3 of 6 rows, NEXT_KEY points at row 4.
  page1 <- sd_json(
    list(sd_value("1"), sd_value("2"), sd_value("3")),
    total = 6, to = 3, next_key = 4
  )
  httr2::local_mocked_responses(function(req) fake_json_response(page1))

  # Remaining pages come back through the mockable fetch seam, NOT the HTTP
  # layer (req_perform_parallel doesn't honour httr2 mocks).
  page2 <- parse_body(sd_json(list(sd_value("4"), sd_value("5"), sd_value("6")),
                              total = 6, to = 6))
  testthat::local_mocked_bindings(
    estat_fetch_bodies = function(reqs, envelope, max_active = 5L) list(page2)
  )

  d <- estat_stats_data("0003217721")
  expect_equal(nrow(d), 6L)
  expect_equal(d$value, as.character(1:6))
})

test_that("a NULL NEXT_KEY means a single page (no fan-out attempted)", {
  json <- sd_json(list(sd_value("1")), total = 1, to = 1, next_key = NULL)
  httr2::local_mocked_responses(function(req) fake_json_response(json))
  # If fan-out were attempted it would call the real network; it must not.
  testthat::local_mocked_bindings(
    estat_fetch_bodies = function(...) stop("should not fan out")
  )
  d <- estat_stats_data("0003217721")
  expect_equal(nrow(d), 1L)
})

test_that("estat_stats_data validates its arguments before the network", {
  expect_error(estat_stats_data(""), class = "estat_error_invalid_arg")
  expect_error(estat_stats_data("abc123"), class = "estat_error_invalid_arg")
  expect_error(estat_stats_data("123", limit = -5), class = "estat_error_invalid_arg")
  expect_error(estat_stats_data("123", start_position = 0), class = "estat_error_invalid_arg")
})

test_that("values_from_bodies bulk-assembles VALUE rows across bodies", {
  b1 <- parse_body(sd_json(list(sd_value("1"), sd_value("2")), total = 4, to = 2, next_key = 3))
  b2 <- parse_body(sd_json(list(sd_value("3"), sd_value("4")), total = 4, to = 4))
  dt <- values_from_bodies(list(b1, b2))
  expect_equal(nrow(dt), 4L)
  expect_equal(dt$value, as.character(1:4))
})

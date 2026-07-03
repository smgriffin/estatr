test_that("pivot_estat_wide spreads an axis's labels across columns", {
  json <- sd_json(
    list(sd_value("11077", cat01 = "00"), sd_value("500", cat01 = "12")),
    total = 2, to = 2
  )
  httr2::local_mocked_responses(function(req) fake_json_response(json))
  d <- get_estat("0003217721")

  wide <- pivot_estat_wide(d, names_from = "cat01")
  expect_s3_class(wide, "tbl_df")
  # One row (same area/time), a column per cat01 label.
  expect_equal(nrow(wide), 1L)
  expect_true(all(c("総数", "労働力人口") %in% names(wide)))
  expect_equal(wide[["総数"]], 11077)
  expect_equal(wide[["労働力人口"]], 500)
})

test_that("pivot_estat_wide validates its arguments", {
  d <- tibble::tibble(area = "x", cat01 = "y", value = 1)
  expect_error(pivot_estat_wide(1), "data frame")
  expect_error(pivot_estat_wide(d, names_from = "nope"), "must be a column")
  expect_error(pivot_estat_wide(d, names_from = "cat01", values_from = "nope"), "not a column")
})

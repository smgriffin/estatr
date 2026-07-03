test_that("estat_meta_info returns one tibble per axis with stable columns", {
  httr2::local_mocked_responses(function(req) fake_json_response(meta_json()))
  m <- estat_meta_info("0003217721")
  expect_named(m, c("cat01", "area"))
  expect_s3_class(m$cat01, "tbl_df")
  expect_true(all(c("code", "name", "level", "unit", "parent") %in% names(m$cat01)))
  expect_equal(m$cat01$name, c("15歳以上人口", "労働力人口"))
  expect_equal(m$cat01$parent, c(NA, "00"))
})

test_that("a single-CLASS axis still yields a one-row tibble", {
  httr2::local_mocked_responses(function(req) fake_json_response(meta_json()))
  m <- estat_meta_info("0003217721")
  expect_equal(nrow(m$area), 1L)
  expect_equal(m$area$code, "00000")
})

test_that("axis display names are attached", {
  httr2::local_mocked_responses(function(req) fake_json_response(meta_json()))
  m <- estat_meta_info("0003217721")
  expect_equal(unname(attr(m, "axis_names")[["cat01"]]), "就業状態")
})

test_that("estat_meta_info validates its argument", {
  expect_error(estat_meta_info(""), class = "estat_error_invalid_arg")
})

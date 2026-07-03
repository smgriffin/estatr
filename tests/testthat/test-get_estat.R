test_that("get_estat decodes codes to labels with paired code columns", {
  json <- sd_json(
    list(sd_value("11077", cat01 = "00"), sd_value("500", cat01 = "12")),
    total = 2, to = 2
  )
  httr2::local_mocked_responses(function(req) fake_json_response(json))

  d <- get_estat("0003217721")
  expect_s3_class(d, "tbl_df")
  # Paired label + code columns.
  expect_true(all(c("area", "area_code", "time", "time_code",
                    "cat01", "cat01_code", "unit", "value", "annotation") %in% names(d)))
  # Values decoded; columns also carry the axis display name as a `label` attr.
  expect_equal(d$area, c("全国", "全国"), ignore_attr = TRUE)
  expect_equal(d$area_code, c("00000", "00000"))
  expect_equal(d$cat01, c("総数", "労働力人口"), ignore_attr = TRUE)
  expect_equal(d$cat01_code, c("00", "12"))
  expect_equal(attr(d$cat01, "label"), "就業状態")
  expect_type(d$value, "double")
  expect_equal(d$value, c(11077, 500))
})

test_that("geography and time columns come first", {
  json <- sd_json(list(sd_value("1")), total = 1, to = 1)
  httr2::local_mocked_responses(function(req) fake_json_response(json))
  d <- get_estat("0003217721")
  expect_equal(names(d)[1:4], c("area", "area_code", "time", "time_code"))
})

test_that("non-numeric markers land in annotation, not silent NA", {
  json <- sd_json(
    list(sd_value("11077"), sd_value("-"), sd_value("***")),
    total = 3, to = 3
  )
  httr2::local_mocked_responses(function(req) fake_json_response(json))
  d <- get_estat("0003217721")
  expect_equal(d$value, c(11077, NA, NA))
  expect_equal(d$annotation, c(NA, "-", "***"))
})

test_that("the notes legend is attached as an attribute", {
  json <- sd_json(list(sd_value("1")), total = 1, to = 1)
  httr2::local_mocked_responses(function(req) fake_json_response(json))
  d <- get_estat("0003217721")
  notes <- attr(d, "notes")
  expect_s3_class(notes, "tbl_df")
  expect_true("*" %in% notes$char)
})

test_that("decode_labels = FALSE returns coded columns only", {
  json <- sd_json(list(sd_value("1")), total = 1, to = 1)
  httr2::local_mocked_responses(function(req) fake_json_response(json))
  d <- get_estat("0003217721", decode_labels = FALSE)
  expect_true("cat01" %in% names(d))
  expect_false("cat01_code" %in% names(d)) # not decoded, so no split
  expect_equal(d$cat01, "00")
})

test_that("as_data_table = TRUE returns a data.table", {
  json <- sd_json(list(sd_value("1")), total = 1, to = 1)
  httr2::local_mocked_responses(function(req) fake_json_response(json))
  d <- get_estat("0003217721", as_data_table = TRUE)
  expect_s3_class(d, "data.table")
})

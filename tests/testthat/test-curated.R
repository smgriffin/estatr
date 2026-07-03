test_that("estat_curated_tables returns the curated lookup", {
  ct <- estat_curated_tables()
  expect_s3_class(ct, "tbl_df")
  expect_true(all(c("key", "statsDataId", "label_en", "label_ja") %in% names(ct)))
  expect_true("labour_force_survey" %in% ct$key)
})

test_that("lookup_curated_id resolves known keys and rejects unknown ones", {
  expect_equal(lookup_curated_id("labour_force_survey"), "0003005798")
  expect_equal(lookup_curated_id("population_census"), "0003433219")
  expect_equal(lookup_curated_id("economic_census"), "0004005652")
  expect_error(lookup_curated_id("does_not_exist"), class = "estat_error_unknown_curated")
})

test_that("all curated entries now resolve to a statsDataId", {
  expect_false(any(is.na(estat_curated_tables()$statsDataId)))
})

test_that("survey wrappers fetch through get_estat with the curated id", {
  json <- sd_json(list(sd_value("10815")), total = 1, to = 1)
  httr2::local_mocked_responses(function(req) fake_json_response(json))
  d <- get_labour_force_survey(limit = 1)
  expect_s3_class(d, "tbl_df")
  expect_equal(d$value, 10815)
})

test_that("prefectures reference data is complete and well-formed", {
  expect_equal(nrow(prefectures), 47L)
  expect_false(any(duplicated(prefectures$code)))
  expect_equal(prefectures$area_code[prefectures$name_en == "Tokyo"], "13000")
  expect_true(all(nchar(prefectures$code) == 2))
})

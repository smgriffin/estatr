search_json <- '{"GET_STATS_LIST":{"RESULT":{"STATUS":0,"ERROR_MSG":""},"DATALIST_INF":{"NUMBER":1,
  "TABLE_INF":[{"@id":"0003005798","STAT_NAME":{"$":"労働力調査"},"STATISTICS_NAME":"基本集計",
  "TITLE":{"$":"就業状態別人口"},"GOV_ORG":{"$":"総務省"},"SURVEY_DATE":"200001","CYCLE":"月次",
  "OTHER_FIELD":"keepme"}]}}}'

test_that("search_estat renames friendly columns and moves them to the front", {
  httr2::local_mocked_responses(function(req) fake_json_response(search_json))
  s <- search_estat("労働力調査")
  expect_s3_class(s, "tbl_df")
  expect_equal(names(s)[1], "id")
  expect_true(all(c("id", "stat_name", "title", "gov_org", "survey_date", "cycle") %in% names(s)))
  # Non-curated raw columns are preserved, after the friendly ones.
  expect_true("OTHER_FIELD" %in% names(s))
  expect_equal(s$stat_name, "労働力調査")
})

test_that("collapse_date_range builds the from-to form e-Stat expects", {
  expect_null(collapse_date_range(NULL, NULL))
  expect_equal(collapse_date_range("2020", NULL), "2020")
  expect_equal(collapse_date_range(NULL, "2021"), "2021")
  expect_equal(collapse_date_range("2020", "2021"), "2020-2021")
})

# A minimal but realistic getStatsList response, including Japanese text and the
# {@code, $} object shape, so the offline test exercises the true parse path.
stats_list_json <- function(status = 0L, msg = "") {
  sprintf(
    '{"GET_STATS_LIST":{"RESULT":{"STATUS":%d,"ERROR_MSG":"%s"},"DATALIST_INF":{"NUMBER":2,"TABLE_INF":[
      {"@id":"0003288322","STAT_NAME":{"@code":"00200521","$":"国勢調査"},"GOV_ORG":{"@code":"00200","$":"総務省"},"TITLE":{"@no":"001","$":"人口"},"CYCLE":"-","SURVEY_DATE":"202010"},
      {"@id":"0003288323","STAT_NAME":{"@code":"00200531","$":"労働力調査"},"GOV_ORG":{"@code":"00200","$":"総務省"},"TITLE":{"@no":"002","$":"就業者数"},"CYCLE":"月次","SURVEY_DATE":"202401"}
    ]}}}',
    status, msg
  )
}

test_that("estat_stats_list returns a tibble with decoded UTF-8 columns", {
  httr2::local_mocked_responses(function(req) fake_json_response(stats_list_json()))

  res <- estat_stats_list(searchWord = "調査", key = "K")
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 2L)
  expect_equal(res$id, c("0003288322", "0003288323"))
  expect_equal(res$STAT_NAME, c("国勢調査", "労働力調査"))
  expect_equal(res$GOV_ORG, c("総務省", "総務省"))
  expect_true(all(c("STAT_NAME_code", "TITLE", "SURVEY_DATE") %in% names(res)))
})

test_that("a single-table response still yields a one-row tibble", {
  one <- '{"GET_STATS_LIST":{"RESULT":{"STATUS":0,"ERROR_MSG":""},"DATALIST_INF":{"NUMBER":1,"TABLE_INF":{"@id":"0003288322","TITLE":{"$":"人口"}}}}}'
  httr2::local_mocked_responses(function(req) fake_json_response(one))
  res <- estat_stats_list(searchWord = "x", key = "K")
  expect_equal(nrow(res), 1L)
  expect_equal(res$id, "0003288322")
})

test_that("an e-Stat error status surfaces as a classed condition, not an empty tibble", {
  httr2::local_mocked_responses(
    function(req) fake_json_response(stats_list_json(status = 100L, msg = "invalid param"))
  )
  expect_error(
    estat_stats_list(searchWord = "x", key = "K"),
    class = "estat_error_invalid_param"
  )
})

test_that("argument validation fails before the network", {
  # No mocked response registered: if validation let these through, the test
  # would attempt a real request. It must error locally instead.
  expect_error(estat_stats_list(searchKind = "9"), class = "rlang_error")
  expect_error(estat_stats_list(limit = -1), class = "estat_error_invalid_arg")
  expect_error(estat_stats_list(statsCode = "123"), class = "estat_error_invalid_arg")
})

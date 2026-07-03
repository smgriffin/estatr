test_that("estat_data_catalog flattens entries with arrays of resources", {
  json <- '{"GET_DATA_CATALOG":{"RESULT":{"STATUS":0,"ERROR_MSG":""},"DATA_CATALOG_LIST_INF":{
    "DATA_CATALOG_INF":[
      {"@id":"A001","DATASET":{"TITLE":"国勢調査"},"RESOURCES":{"RESOURCE":[
        {"@id":"r1","URL":"https://example/1.csv"},
        {"@id":"r2","URL":"https://example/2.xlsx"}]}}
    ]}}}'
  httr2::local_mocked_responses(function(req) fake_json_response(json))

  dc <- estat_data_catalog(searchWord = "国勢調査")
  expect_s3_class(dc, "tbl_df")
  expect_equal(nrow(dc), 1L)
  expect_false(any(duplicated(names(dc))))
  # Both array resources get distinct, indexed columns.
  expect_true(any(grepl("RESOURCES_RESOURCE_1", names(dc))))
  expect_true(any(grepl("RESOURCES_RESOURCE_2", names(dc))))
})

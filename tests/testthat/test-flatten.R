test_that("flatten_record collapses {@code, $} objects onto the parent name", {
  rec <- list(
    "@id" = "0003288322",
    STAT_NAME = list("@code" = "00200531", "$" = "国勢調査")
  )
  flat <- flatten_record(rec)
  expect_equal(flat$id, "0003288322")
  expect_equal(flat$STAT_NAME_code, "00200531")
  expect_equal(flat$STAT_NAME, "国勢調査") # UTF-8 preserved
})

test_that("records_to_dt fills missing columns across heterogeneous records", {
  recs <- list(
    list("@id" = "1", TITLE = list("$" = "a")),
    list("@id" = "2") # no TITLE
  )
  dt <- records_to_dt(recs)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("TITLE" %in% names(dt))
  expect_true(is.na(dt$TITLE[2]))
})

test_that("records_to_dt handles the empty case", {
  dt <- records_to_dt(list())
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("flatten_record indexes arrays of objects instead of colliding names", {
  rec <- list(
    "@id" = "A",
    RESOURCES = list(RESOURCE = list(
      list("@id" = "r1", URL = "u1"),
      list("@id" = "r2", URL = "u2")
    ))
  )
  flat <- flatten_record(rec)
  expect_false(any(duplicated(names(flat))))
  expect_equal(flat[["RESOURCES_RESOURCE_1_id"]], "r1")
  expect_equal(flat[["RESOURCES_RESOURCE_2_URL"]], "u2")
})

test_that("as_record_list normalises single vs. many records", {
  single <- list("@id" = "1", TITLE = "x")
  many <- list(list("@id" = "1"), list("@id" = "2"))
  expect_length(as_record_list(single), 1L)
  expect_length(as_record_list(many), 2L)
  expect_length(as_record_list(NULL), 0L)
})

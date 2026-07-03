test_that("split_batches chunks offsets by size", {
  expect_equal(split_batches(1:5, 2), list(c(1, 2), c(3, 4), 5))
  expect_equal(split_batches(integer(0), 3), list())
})

test_that("checkpoint_load/save round-trip a store", {
  cp <- withr::local_tempfile(fileext = ".rds")
  expect_equal(checkpoint_load(cp), list()) # missing file -> empty
  checkpoint_save(cp, list("1" = data.table::data.table(value = "x")))
  loaded <- checkpoint_load(cp)
  expect_equal(names(loaded), "1")
})

test_that("checkpoint records completed offsets across pages", {
  withr::local_options(estatr.page_size = 3L)
  cp <- withr::local_tempfile(fileext = ".rds")

  page1 <- sd_json(list(sd_value("1"), sd_value("2"), sd_value("3")),
                   total = 6, to = 3, next_key = 4)
  httr2::local_mocked_responses(function(req) fake_json_response(page1))
  page2 <- parse_body(sd_json(list(sd_value("4"), sd_value("5"), sd_value("6")),
                              total = 6, to = 6))
  testthat::local_mocked_bindings(
    estat_fetch_bodies = function(reqs, envelope, max_active = 5L) list(page2)
  )

  d <- estat_stats_data("0003217721", checkpoint = cp)
  expect_equal(nrow(d), 6L)
  expect_equal(d$value, as.character(1:6))
  store <- readRDS(cp)
  expect_setequal(names(store), c("1", "4")) # page-one offset + fanned offset
})

test_that("resuming re-requests only the missing offsets", {
  withr::local_options(estatr.page_size = 3L)
  cp <- withr::local_tempfile(fileext = ".rds")
  # Pre-seed as if offset 4 (rows 4-6) already completed in a prior, crashed run.
  saveRDS(list("4" = data.table::data.table(value = c("4", "5", "6"))), cp)

  page1 <- sd_json(list(sd_value("1"), sd_value("2"), sd_value("3")),
                   total = 6, to = 3, next_key = 4)
  httr2::local_mocked_responses(function(req) fake_json_response(page1))
  testthat::local_mocked_bindings(
    estat_fetch_bodies = function(...) stop("offset already checkpointed; must not refetch")
  )

  d <- estat_stats_data("0003217721", checkpoint = cp)
  expect_equal(nrow(d), 6L)
  expect_equal(d$value, as.character(1:6))
})

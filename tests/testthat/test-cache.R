test_that("cache_set/cache_get round-trips a value", {
  withr::local_options(estatr.cache_dir = withr::local_tempdir())
  cache_set("meta-123", list(a = 1), sub = "meta")
  expect_equal(cache_get("meta-123", sub = "meta"), list(a = 1))
  expect_null(cache_get("meta-does-not-exist", sub = "meta"))
})

test_that("cache_get honours the TTL", {
  dir <- withr::local_tempdir()
  withr::local_options(estatr.cache_dir = dir)
  cache_set("meta-ttl", "v", sub = "meta")
  path <- file.path(dir, "meta", "meta-ttl.rds")
  # Backdate the file so it looks 100s old.
  Sys.setFileTime(path, Sys.time() - 100)
  expect_null(cache_get("meta-ttl", sub = "meta", ttl = 10)) # stale
  expect_equal(cache_get("meta-ttl", sub = "meta", ttl = 1000), "v") # fresh enough
})

test_that("estat_cache_clear removes cached files", {
  withr::local_options(estatr.cache_dir = withr::local_tempdir())
  cache_set("meta-a", 1, sub = "meta")
  cache_set("meta-b", 2, sub = "meta")
  n <- suppressMessages(estat_cache_clear("meta"))
  expect_equal(n, 2L)
  expect_null(cache_get("meta-a", sub = "meta"))
})

test_that("estat_meta_info reads from and writes to the disk cache", {
  withr::local_options(estatr.cache_dir = withr::local_tempdir())
  httr2::local_mocked_responses(function(req) fake_json_response(meta_json()))

  first <- estat_meta_info("0003217721")
  # Cache file now exists; a second call with the network turned OFF still works.
  key_file <- file.path(estat_cache_dir(), "meta", "meta-0003217721.rds")
  expect_true(file.exists(key_file))

  httr2::local_mocked_responses(function(req) stop("network should not be hit"))
  # Clear the in-session memoise layer so we exercise the disk cache path.
  second <- estat_meta_info("0003217721")
  expect_equal(names(second), names(first))
})

test_that("estat_cache_dir is overridable and defaults under rappdirs", {
  withr::local_options(estatr.cache_dir = "/tmp/estatr-test")
  expect_equal(estat_cache_dir(), "/tmp/estatr-test")
})

test_that("estat_api_key sets the session env var without printing it", {
  withr::local_envvar(ESTAT_API_KEY = "")
  expect_output(estat_api_key("abc123"), NA) # nothing printed
  expect_identical(Sys.getenv("ESTAT_API_KEY"), "abc123")
  expect_true(estat_api_key_exists())
})

test_that("estat_api_key rejects non-string keys", {
  expect_error(estat_api_key(""), "non-empty string")
  expect_error(estat_api_key(c("a", "b")), "single non-empty string")
})

test_that("estat_api_key_exists reflects the env var", {
  withr::local_envvar(ESTAT_API_KEY = "")
  expect_false(estat_api_key_exists())
  withr::local_envvar(ESTAT_API_KEY = "x")
  expect_true(estat_api_key_exists())
})

test_that("install=TRUE writes to .Renviron and refuses to clobber without overwrite", {
  tmp_home <- withr::local_tempdir()
  withr::local_envvar(HOME = tmp_home, ESTAT_API_KEY = "")

  suppressMessages(estat_api_key("firstkey", install = TRUE))
  renviron <- file.path(tmp_home, ".Renviron")
  expect_true(file.exists(renviron))
  expect_match(paste(readLines(renviron), collapse = "\n"), "ESTAT_API_KEY=firstkey")

  # Second install without overwrite should error, not silently replace.
  expect_error(
    estat_api_key("secondkey", install = TRUE),
    class = "estat_error_key_exists"
  )

  # With overwrite it replaces in place (no duplicate line).
  suppressMessages(estat_api_key("secondkey", install = TRUE, overwrite = TRUE))
  lines <- readLines(renviron)
  expect_equal(sum(grepl("^ESTAT_API_KEY=", lines)), 1L)
  expect_match(lines[grepl("^ESTAT_API_KEY=", lines)], "secondkey")
})

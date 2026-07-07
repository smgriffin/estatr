test_that("estat_lang validates and normalises the language code", {
  expect_equal(estat_lang("E"), "E")
  expect_equal(estat_lang("j"), "J") # case-insensitive
  expect_error(estat_lang("X"), class = "estat_error_invalid_arg")
  expect_error(estat_lang(c("E", "J")), class = "estat_error_invalid_arg")
})

test_that("requests default to English and carry the lang query param", {
  req <- estat_request("getStatsList", params = list(searchWord = "x"), key = "K")
  expect_match(req$url, "lang=E")
})

test_that("the estatr.lang option sets the default language", {
  withr::local_options(estatr.lang = "J")
  req <- estat_request("getStatsList", params = list(), key = "K")
  expect_match(req$url, "lang=J")
})

test_that("an explicit lang argument overrides the option", {
  withr::local_options(estatr.lang = "J")
  req <- estat_request("getStatsList", params = list(), key = "K", lang = "E")
  expect_match(req$url, "lang=E")
})

test_that("meta_cache_key is language-specific", {
  expect_equal(meta_cache_key("123", "E"), "meta-E-123")
  expect_equal(meta_cache_key("123", "J"), "meta-J-123")
  expect_false(identical(meta_cache_key("123", "E"), meta_cache_key("123", "J")))
})

test_that("try_with_lang_fallback retries English failures in Japanese", {
  # A fetch that errors under English but succeeds under Japanese.
  fetch <- function(l) {
    if (identical(l, "E")) {
      cli::cli_abort("no english", class = c("estat_error_no_data", "estat_api_error", "estat_error"))
    }
    "japanese-result"
  }
  expect_warning(
    got <- try_with_lang_fallback("E", fetch),
    "no English release"
  )
  expect_equal(got$result, "japanese-result")
  expect_equal(got$lang, "J")
})

test_that("try_with_lang_fallback does not retry when Japanese was requested", {
  fetch <- function(l) cli::cli_abort("boom", class = c("estat_api_error", "estat_error"))
  expect_error(try_with_lang_fallback("J", fetch), class = "estat_api_error")
})

test_that("try_with_lang_fallback re-raises the English error if Japanese also fails", {
  fetch <- function(l) cli::cli_abort(
    paste("fail", l), class = c("estat_api_error", "estat_error")
  )
  # English error is surfaced (not the Japanese one), and no warning is emitted.
  expect_error(
    expect_no_warning(try_with_lang_fallback("E", fetch)),
    "fail E"
  )
})

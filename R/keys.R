# e-Stat appId (API key) management, modelled on tidycensus::census_api_key().
#
# The key is never stored in package state; it lives in an environment variable
# (optionally persisted to .Renviron) and is read at call time.

#' Set your e-Stat API key
#'
#' Registers your e-Stat `appId` for the current session, and optionally writes
#' it to your `.Renviron` so it is available in future sessions. The e-Stat API
#' requires a free `appId`; obtain one at <https://www.e-stat.go.jp/api/>.
#'
#' The key is a secret. This function never prints it, and you should never
#' commit it to version control or paste it into issues. If a key is ever
#' exposed, delete and reissue it on the e-Stat mypage (up to 3 are allowed per
#' account).
#'
#' @param key Your e-Stat `appId`, a string.
#' @param install If `TRUE`, write the key to `.Renviron` so it persists across
#'   sessions. Defaults to `FALSE` (session only).
#' @param overwrite If `TRUE`, replace an existing `ESTAT_API_KEY` entry in
#'   `.Renviron`. Ignored when `install = FALSE`.
#' @return Invisibly, the key (so it can be piped), though it is never printed.
#' @export
#' @examples
#' \dontrun{
#' # Session only
#' estat_api_key("your-app-id")
#'
#' # Persist for future sessions
#' estat_api_key("your-app-id", install = TRUE)
#' }
estat_api_key <- function(key, install = FALSE, overwrite = FALSE) {
  if (!rlang::is_string(key) || !nzchar(key)) {
    cli::cli_abort("{.arg key} must be a single non-empty string.")
  }

  # Session value takes effect immediately.
  args <- stats::setNames(list(key), estat_key_envvar)
  do.call(Sys.setenv, args)

  if (isTRUE(install)) {
    write_key_to_renviron(key, overwrite = overwrite)
  }

  invisible(key)
}

#' Is an e-Stat API key available?
#'
#' @return `TRUE` if a non-empty `ESTAT_API_KEY` is set, otherwise `FALSE`.
#' @export
estat_api_key_exists <- function() {
  nzchar(Sys.getenv(estat_key_envvar))
}

# Read the current key. Internal; callers get a clear error from estat_request()
# if it is missing.
get_estat_key <- function() {
  key <- Sys.getenv(estat_key_envvar)
  if (nzchar(key)) key else NULL
}

# Append or replace ESTAT_API_KEY in the user's .Renviron.
write_key_to_renviron <- function(key, overwrite = FALSE) {
  renviron <- file.path(Sys.getenv("HOME"), ".Renviron")

  lines <- if (file.exists(renviron)) readLines(renviron, warn = FALSE) else character()
  key_line <- paste0(estat_key_envvar, "=", key)
  existing <- grepl(paste0("^", estat_key_envvar, "="), lines)

  if (any(existing)) {
    if (!isTRUE(overwrite)) {
      cli::cli_abort(
        c(
          "{.envvar {estat_key_envvar}} already exists in {.path {renviron}}.",
          "i" = "Call {.code estat_api_key(key, install = TRUE, overwrite = TRUE)} to replace it."
        ),
        class = "estat_error_key_exists"
      )
    }
    lines[existing] <- key_line
  } else {
    lines <- c(lines, key_line)
  }

  writeLines(lines, renviron)
  cli::cli_inform(c(
    "v" = "Wrote {.envvar {estat_key_envvar}} to {.path {renviron}}.",
    "i" = "Restart R or run {.code readRenviron('~/.Renviron')} to use it in this session."
  ))
  invisible(renviron)
}

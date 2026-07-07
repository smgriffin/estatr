# Small internal helpers. Kept dependency-free and base-R where possible.

# Null-coalescing. Defined locally rather than relying on base `%||%`, which
# only exists from R 4.4.0 (we support R >= 4.1).
`%||%` <- function(x, y) if (is.null(x)) y else x

# Drop NULL elements from a list (leaves length-0 vectors alone).
compact <- function(x) x[!vapply(x, is.null, logical(1))]

# Normalise and validate the e-Stat language code. "E" (English) is the package
# default; "J" returns Japanese. English falls back to Japanese text for the
# occasional item that has no official translation, so it never returns blanks.
estat_lang <- function(lang = getOption("estatr.lang", "E")) {
  lang <- toupper(as.character(lang))
  if (length(lang) != 1 || !lang %in% c("E", "J")) {
    cli::cli_abort(
      '{.arg lang} must be "E" (English) or "J" (Japanese).',
      class = "estat_error_invalid_arg"
    )
  }
  lang
}

# Redact the appId out of a string (URL, message, echoed parameter block) so it
# can never leak through an error condition, verbose log, or fixture.
redact_appid <- function(x) {
  if (!is.character(x)) return(x)
  gsub(
    paste0("(", estat_appid_param, "=)[^&\\s\"]+"),
    "\\1<hidden>",
    x,
    perl = TRUE
  )
}

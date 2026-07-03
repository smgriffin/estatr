#' @keywords internal
"_PACKAGE"

## Declare that this package is aware of data.table's semantics so that
## `[.data.table` uses data.table dispatch inside package code, and quiet the
## `R CMD check` "no visible binding for global variable" NOTEs that data.table
## non-standard evaluation (`:=`, `.`, bare column names) otherwise produces.
## Symbols used unquoted inside data.table calls are declared here as they are
## introduced; keep this list in sync with the internal parsing/join code.
.datatable.aware <- TRUE

utils::globalVariables(c("."))

## usethis namespace: start
#' @importFrom data.table :=
#' @importFrom data.table .SD
#' @importFrom lifecycle deprecated
#' @importFrom rlang .data
## usethis namespace: end
NULL

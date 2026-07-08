# Search the e-Stat catalog for statistical tables

Low-level wrapper around the e-Stat `getStatsList` endpoint. Searches
the government-wide statistics catalog and returns a tibble of matching
tables, one row per table, including the `id` (the `statsDataId` you
will pass to
[`estat_stats_data()`](https://smgriffin.github.io/estatr/reference/estat_stats_data.md)
once that wrapper is implemented).

## Usage

``` r
estat_stats_list(
  searchWord = NULL,
  statsCode = NULL,
  surveyYears = NULL,
  statsField = NULL,
  searchKind = NULL,
  limit = NULL,
  startPosition = NULL,
  ...,
  lang = getOption("estatr.lang", "E"),
  key = get_estat_key()
)
```

## Arguments

- searchWord:

  Keyword(s) to search. Japanese is supported and encoded as UTF-8.
  Combine terms with `AND`/`OR` per the e-Stat API.

- statsCode:

  Government statistics code to filter by (5 or 8 digits).

- surveyYears:

  Survey period filter: `yyyy`, `yyyymm`, or `yyyymm-yyyymm`.

- statsField:

  Statistics field code (2 or 4 digits).

- searchKind:

  Data kind: `1` (statistics, default) or `2` (regional statistics /
  sub-datasets).

- limit:

  Maximum number of tables to return.

- startPosition:

  1-based row offset to start from.

- ...:

  Further query parameters passed through to `getStatsList` verbatim
  (e.g. `updatedDate`, `openYears`).

- lang:

  Label language: `"E"` for English (the package default, settable with
  `options(estatr.lang = )`) or `"J"` for Japanese. Tables that have no
  English release fall back to Japanese automatically, with a warning.

- key:

  e-Stat appId. Defaults to the stored key.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per matching table. Returns a zero-row tibble when the search
matches nothing.

## Details

This is a power-user function that mirrors the API closely.
Higher-level, friendlier search
([`search_estat()`](https://smgriffin.github.io/estatr/reference/search_estat.md))
is planned for a later milestone.

## Examples

``` r
if (FALSE) { # \dontrun{
estat_api_key("your-app-id")
# Tables mentioning the Labour Force Survey
estat_stats_list(searchWord = "労働力調査")
} # }
```

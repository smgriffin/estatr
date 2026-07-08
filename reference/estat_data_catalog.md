# Search the e-Stat data catalog for datasets and files

Wraps the e-Stat `getDataCatalog` endpoint, which returns catalog
entries — datasets and their downloadable resources (Excel/CSV/PDF URLs)
— rather than machine-readable data values. Use
[`estat_stats_data()`](https://smgriffin.github.io/estatr/reference/estat_stats_data.md)
/
[`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)
for the actual numbers.

## Usage

``` r
estat_data_catalog(
  searchWord = NULL,
  ...,
  lang = getOption("estatr.lang", "E"),
  key = get_estat_key()
)
```

## Arguments

- searchWord:

  Keyword(s) to search. Japanese is supported.

- ...:

  Further query parameters passed to `getDataCatalog` verbatim (e.g.
  `statsCode`, `dataType`, `limit`, `startPosition`).

- lang:

  Label language: `"E"` for English (the package default, settable with
  `options(estatr.lang = )`) or `"J"` for Japanese. Tables that have no
  English release fall back to Japanese automatically, with a warning.

- key:

  e-Stat appId. Defaults to the stored key.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
catalog entries, one row per entry. Returns a zero-row tibble when
nothing matches.

## Examples

``` r
if (FALSE) { # \dontrun{
estat_data_catalog(searchWord = "国勢調査", limit = 10)
} # }
```

# Retrieve classification metadata for an e-Stat table

Wraps the e-Stat `getMetaInfo` endpoint. Returns the classification
metadata needed to decode a table's numeric codes into labels: one
tibble per classification axis (`tab`, `cat01`, ..., `area`, `time`),
keyed by the axis id, each with `code`, `name`, `level`, `unit`, and
`parent` columns.

## Usage

``` r
estat_meta_info(
  statsDataId,
  lang = getOption("estatr.lang", "E"),
  key = get_estat_key(),
  cache = TRUE,
  cache_ttl = getOption("estatr.cache_ttl", 30 * 24 * 3600)
)
```

## Arguments

- statsDataId:

  The table id whose metadata to fetch.

- lang:

  Label language: `"E"` for English (the package default, settable with
  `options(estatr.lang = )`) or `"J"` for Japanese. Tables that have no
  English release fall back to Japanese automatically, with a warning.

- key:

  e-Stat appId. Defaults to the stored key.

- cache:

  If `TRUE` (default), read/write the parsed metadata from the on-disk
  cache (see
  [`estat_cache_dir()`](https://smgriffin.github.io/estatr/reference/estat_cache_dir.md));
  metadata rarely changes, so this avoids a network round-trip on repeat
  calls. Set `FALSE` to force a fetch.

- cache_ttl:

  Maximum age, in seconds, of a cached entry before it is refetched.
  Defaults to `options(estatr.cache_ttl)` or 30 days.

## Value

A named list of
[tibbles](https://tibble.tidyverse.org/reference/tibble.html), one per
classification axis, plus a `table_info` attribute with the table's
overall description.

## Examples

``` r
if (FALSE) { # \dontrun{
meta <- estat_meta_info("0003217721")
meta$cat01 # labels for the first category axis
} # }
```

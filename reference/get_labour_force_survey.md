# Get the Labour Force Survey (basic tabulation)

Convenience wrapper for the Labour Force Survey table of 15-and-over
population by labour-force status. Equivalent to
`get_estat_curated("labour_force_survey", ...)`.

## Usage

``` r
get_labour_force_survey(...)
```

## Arguments

- ...:

  Arguments passed on to
  [`get_estat`](https://smgriffin.github.io/estatr/reference/get_estat.md)

  `decode_labels`

  :   If `TRUE` (default), join metadata labels onto the coded values.
      `FALSE` skips the metadata join entirely and returns just the
      coded columns — a power-user fast path.

  `as_data_table`

  :   If `TRUE`, return the internal `data.table` directly instead of
      converting to a tibble, for bulk-analysis users who don't want
      even the boundary conversion. Defaults to `FALSE`.

  `limit`

  :   Maximum number of rows to return. `NULL` (default) returns all
      matching rows.

  `checkpoint`

  :   Optional path to a checkpoint file for resumable pulls (see
      [`estat_stats_data()`](https://smgriffin.github.io/estatr/reference/estat_stats_data.md)).

  `geometry`

  :   If `TRUE`, join e-Stat boundary polygons onto the result by
      `area_code` and return an
      [sf](https://r-spatial.github.io/sf/reference/sf.html) object for
      choropleth mapping (see
      [`estat_join_geometry()`](https://smgriffin.github.io/estatr/reference/estat_join_geometry.md)).
      Requires the sf package and `decode_labels = TRUE`. Defaults to
      `FALSE`.

  `geometry_level,geometry_year,geometry_datum,geometry_designated_cities`

  :   Passed to
      [`estat_join_geometry()`](https://smgriffin.github.io/estatr/reference/estat_join_geometry.md)
      when `geometry = TRUE`. Match `geometry_year` to the census year
      of your data.

  `lang`

  :   Label language: `"E"` for English (the package default, settable
      with `options(estatr.lang = )`) or `"J"` for Japanese. Tables that
      have no English release fall back to Japanese automatically, with
      a warning.

  `key`

  :   e-Stat appId. Defaults to the stored key.

## Value

The tidy tibble from
[`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md).

## Examples

``` r
if (FALSE) { # \dontrun{
get_labour_force_survey(limit = 500)
} # }
```

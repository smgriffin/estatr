# Get tidy, labelled data from e-Stat

The main entry point. Given a `statsDataId`, fetches the data and its
classification metadata in one call, decodes every numeric code to a
human-readable label, and returns a tidy tibble: one row per observation
with paired label/code columns for each classification axis (e.g.
`area` + `area_code`, `time` + `time_code`), the `unit`, a numeric
`value`, and an `annotation` column preserving any non-numeric markers
(suppressed cells, footnote symbols) instead of silently coercing them
to `NA`.

## Usage

``` r
get_estat(
  statsDataId,
  ...,
  decode_labels = TRUE,
  as_data_table = FALSE,
  limit = NULL,
  checkpoint = NULL,
  geometry = FALSE,
  geometry_level = "auto",
  geometry_year = 2020,
  geometry_datum = "2000",
  geometry_designated_cities = "both",
  lang = getOption("estatr.lang", "E"),
  key = get_estat_key()
)
```

## Arguments

- statsDataId:

  The table id to retrieve (from
  [`estat_stats_list()`](https://smgriffin.github.io/estatr/reference/estat_stats_list.md)
  or
  [`search_estat()`](https://smgriffin.github.io/estatr/reference/search_estat.md)).

- ...:

  Filter parameters passed to `getStatsData` (e.g. `cdCat01`, `cdArea`,
  `cdTime`, `cdTimeFrom`, `cdTimeTo`).

- decode_labels:

  If `TRUE` (default), join metadata labels onto the coded values.
  `FALSE` skips the metadata join entirely and returns just the coded
  columns — a power-user fast path.

- as_data_table:

  If `TRUE`, return the internal `data.table` directly instead of
  converting to a tibble, for bulk-analysis users who don't want even
  the boundary conversion. Defaults to `FALSE`.

- limit:

  Maximum number of rows to return. `NULL` (default) returns all
  matching rows.

- checkpoint:

  Optional path to a checkpoint file for resumable pulls (see
  [`estat_stats_data()`](https://smgriffin.github.io/estatr/reference/estat_stats_data.md)).

- geometry:

  If `TRUE`, join e-Stat boundary polygons onto the result by
  `area_code` and return an
  [sf](https://r-spatial.github.io/sf/reference/sf.html) object for
  choropleth mapping (see
  [`estat_join_geometry()`](https://smgriffin.github.io/estatr/reference/estat_join_geometry.md)).
  Requires the sf package and `decode_labels = TRUE`. Defaults to
  `FALSE`.

- geometry_level, geometry_year, geometry_datum,
  geometry_designated_cities:

  Passed to
  [`estat_join_geometry()`](https://smgriffin.github.io/estatr/reference/estat_join_geometry.md)
  when `geometry = TRUE`. Match `geometry_year` to the census year of
  your data.

- lang:

  Label language: `"E"` for English (the package default, settable with
  `options(estatr.lang = )`) or `"J"` for Japanese. Tables that have no
  English release fall back to Japanese automatically, with a warning.

- key:

  e-Stat appId. Defaults to the stored key.

## Value

A tidy [tibble](https://tibble.tidyverse.org/reference/tibble.html) (or
`data.table` if `as_data_table`, or an
[sf](https://r-spatial.github.io/sf/reference/sf.html) object if
`geometry = TRUE`), with a `notes` attribute holding the table's
annotation legend.

## Examples

``` r
if (FALSE) { # \dontrun{
estat_api_key("your-app-id")
# Labour Force Survey, one category, decoded to labels
get_estat("0003217721", cdCat03 = "1", limit = 500)
} # }
```

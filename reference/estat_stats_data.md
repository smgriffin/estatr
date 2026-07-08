# Retrieve statistical data values from e-Stat

Low-level wrapper around the e-Stat `getStatsData` endpoint. Given a
`statsDataId` (from
[`estat_stats_list()`](https://smgriffin.github.io/estatr/reference/estat_stats_list.md))
and optional filter codes, returns a tibble of the raw data values, one
row per observation, with e-Stat's numeric classification codes intact
(`tab`, `cat01`, ..., `area`, `time`, `unit`, `value`).

## Usage

``` r
estat_stats_data(
  statsDataId,
  ...,
  limit = NULL,
  start_position = 1L,
  checkpoint = NULL,
  lang = getOption("estatr.lang", "E"),
  key = get_estat_key()
)
```

## Arguments

- statsDataId:

  The table id to retrieve (a ~10-digit string).

- ...:

  Filter parameters passed to `getStatsData`, e.g. `cdCat01`, `cdArea`,
  `cdTime`, `cdTimeFrom`, `cdTimeTo`. Vectors are comma-joined into
  e-Stat's expected code-list form.

- limit:

  Maximum number of rows to return. `NULL` (default) returns all
  matching rows, paginating as needed.

- start_position:

  1-based absolute row offset to start from.

- checkpoint:

  Optional path to a checkpoint file for resumable pulls. When set, each
  page's rows are persisted keyed by absolute offset, so an interrupted
  large pull resumes by re-requesting only the missing pages.

- lang:

  Label language: `"E"` for English (the package default, settable with
  `options(estatr.lang = )`) or `"J"` for Japanese. Tables that have no
  English release fall back to Japanese automatically, with a warning.

- key:

  e-Stat appId. Defaults to the stored key.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of coded
data values.

## Details

Pagination is automatic: e-Stat caps each response at 100,000 records,
and this function fetches the remaining pages concurrently (bounded,
throttled) using the total record count reported on the first page. For
decoded, analysis-ready output with human-readable labels, use
[`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md).

## Examples

``` r
if (FALSE) { # \dontrun{
estat_api_key("your-app-id")
estat_stats_data("0003217721", cdCat03 = "1", limit = 100)
} # }
```

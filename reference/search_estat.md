# Search the e-Stat catalog (interactive-friendly)

A friendlier wrapper over
[`estat_stats_list()`](https://smgriffin.github.io/estatr/reference/estat_stats_list.md)
for finding tables interactively. Returns a tibble with the most useful
columns renamed to stable snake_case (`id`, `stat_name`, `title`,
`gov_org`, `survey_date`, ...) and moved to the front, with the raw
columns kept after them.

## Usage

``` r
search_estat(
  keyword = NULL,
  gov_org = NULL,
  updated_from = NULL,
  updated_to = NULL,
  limit = 100L,
  ...,
  lang = getOption("estatr.lang", "E"),
  key = get_estat_key()
)
```

## Arguments

- keyword:

  Keyword(s) to search for. Japanese is supported. Combine terms with
  `AND`/`OR` per the e-Stat API.

- gov_org:

  Government organisation code to filter by (passed as `statsCode`'s org
  prefix is not assumed; use
  [`estat_stats_list()`](https://smgriffin.github.io/estatr/reference/estat_stats_list.md)
  for full control).

- updated_from, updated_to:

  Optional update-date bounds (`yyyymmdd` or `yyyymm`) to restrict to
  recently refreshed tables.

- limit:

  Maximum number of tables to return (default 100).

- ...:

  Further parameters passed through to
  [`estat_stats_list()`](https://smgriffin.github.io/estatr/reference/estat_stats_list.md).

- lang:

  Label language: `"E"` for English (the package default, settable with
  `options(estatr.lang = )`) or `"J"` for Japanese. Tables that have no
  English release fall back to Japanese automatically, with a warning.

- key:

  e-Stat appId. Defaults to the stored key.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
matching tables, friendly columns first.

## Examples

``` r
if (FALSE) { # \dontrun{
search_estat("労働力調査")
search_estat("国勢調査", updated_from = "2020")
} # }
```

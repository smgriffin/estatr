# Get a curated e-Stat table by name

Fetches a curated table via
[`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)
using a friendly `key` from
[`estat_curated_tables()`](https://smgriffin.github.io/estatr/reference/estat_curated_tables.md),
so you don't need to know its `statsDataId`.

## Usage

``` r
get_estat_curated(key, ...)
```

## Arguments

- key:

  A curated table key, e.g. `"labour_force_survey"`.

- ...:

  Passed to
  [`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)
  (filters, `limit`, `decode_labels`, ...).

## Value

The tidy tibble from
[`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md).

## Examples

``` r
if (FALSE) { # \dontrun{
get_estat_curated("labour_force_survey", limit = 500)
} # }
```

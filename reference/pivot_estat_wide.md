# Pivot tidy e-Stat output to wide form

Reshapes the long/tidy output of
[`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)
into wide form, spreading the labels of one classification axis across
columns. Mirrors tidycensus's `output = "wide"`, but as an explicit
opt-in step rather than the default.

## Usage

``` r
pivot_estat_wide(data, names_from, values_from = "value", id_cols = NULL)
```

## Arguments

- data:

  A tibble or data.frame from
  [`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)
  (with `decode_labels`).

- names_from:

  Column whose values become the new column names (e.g. `"cat01"`). Its
  paired `_code` column is dropped from the id set.

- values_from:

  Column holding the cell values to spread. Defaults to `"value"`.

- id_cols:

  Columns identifying each output row. Defaults to every column except
  `names_from` (and its `_code` partner), `values_from`, and
  `annotation`.

## Value

A wide [tibble](https://tibble.tidyverse.org/reference/tibble.html), one
row per unique combination of `id_cols`.

## Examples

``` r
if (FALSE) { # \dontrun{
d <- get_estat("0003217721", limit = 500)
pivot_estat_wide(d, names_from = "cat01")
} # }
```

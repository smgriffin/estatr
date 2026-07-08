# Attach boundary geometry to e-Stat data

Joins e-Stat boundary polygons onto a tidy
[`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)
result by `area_code`, returning an sf object ready for choropleth
mapping. Each data row receives its area's geometry (so a long time
series repeats geometry per period, matching the tidycensus
long-plus-geometry convention).

## Usage

``` r
estat_join_geometry(
  data,
  level = c("auto", "municipality", "prefecture", "small_area"),
  year = 2020,
  datum = c("2000", "2011"),
  designated_cities = c("both", "ward", "city")
)
```

## Arguments

- data:

  A tibble from
  [`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)
  (decoded, with an `area_code` column).

- level:

  Geographic level, or `"auto"` (default) to infer: `"prefecture"` if
  every `area_code` ends in `"000"`, otherwise `"municipality"`.

- year, datum, designated_cities:

  Passed to
  [`estat_boundaries()`](https://smgriffin.github.io/estatr/reference/estat_boundaries.md).
  Match `year` to your data's census year. `designated_cities` defaults
  to `"both"` so data coded at either ward or parent-city level joins.

## Value

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object: the
input columns plus a `geometry` column.

## Examples

``` r
if (FALSE) { # \dontrun{
d <- get_population_census(cdCat01 = "0")
sf_d <- estat_join_geometry(d, level = "prefecture", year = 2020)
} # }
```

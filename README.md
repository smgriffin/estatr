<!-- README.md is generated from README.Rmd. Please edit that file -->

# estatr

<!-- badges: start -->
[![R-CMD-check](https://github.com/smgriffin/estatr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/smgriffin/estatr/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/smgriffin/estatr/graph/badge.svg)](https://app.codecov.io/gh/smgriffin/estatr)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

`estatr` is a tidy, [tidycensus](https://walker-data.com/tidycensus/)-style R
interface to the Japanese government-wide statistics catalog served by the
**e-Stat API** (`api.e-stat.go.jp`) — Population Census, Labour Force Survey,
Economic Census, and the rest of the official catalog.

It wraps table search, classification metadata, and data retrieval; decodes
e-Stat's numeric codes into human-readable labels; and returns tibbles that pipe
straight into the tidyverse. Internally it uses `data.table` for speed on large
tables, converting to a plain tibble only at the return boundary.

> **Status:** development version, feature-complete for a first release. Search,
> metadata, data retrieval with automatic parallel pagination, label decoding,
> caching, resumable pulls, and choropleth-ready boundary geometry
> (`geometry = TRUE`, via the suggested `sf` package) are all in place.

## Installation

``` r
# install.packages("pak")
pak::pak("smgriffin/estatr")
```

## Authentication

The e-Stat API requires a free `appId`. Sign up at
<https://www.e-stat.go.jp/api/> and issue an application ID, then register it
with:

``` r
library(estatr)
estat_api_key("your-app-id", install = TRUE)
```

This writes `ESTAT_API_KEY` to your `.Renviron` so it is available in future
sessions. The key is a secret: never commit it or paste it into issues.

## Usage

``` r
library(estatr)

# 1. Find a table
tables <- search_estat("労働力調査") # Labour Force Survey

# 2. Get tidy, labelled data in one call (data + metadata, decoded)
d <- get_estat("0003217721", limit = 500)
#> # A tibble: 500 × 9
#>   area  area_code time            time_code  cat01        cat01_code unit  value annotation
#>   <chr> <chr>     <chr>           <chr>      <chr>        <chr>      <chr> <dbl> <chr>
#> 1 全国  00000     2018年1～3月期  2018000103 15歳以上人口 00         万人  11077 NA
#> …

# 3. Or skip the id lookup with a curated shortcut
lfs <- get_labour_force_survey(limit = 500)

# 4. Map it: get an sf object with official e-Stat boundaries joined on
library(sf)
pop <- get_estat("0003433219", cdCat01 = "0", geometry = TRUE,
                 geometry_level = "prefecture", geometry_year = 2020)
```

`get_estat()` returns one row per observation with paired label/code columns,
a numeric `value`, and an `annotation` column preserving suppressed/footnoted
markers. See `vignette("estatr")` to get started.

## Data source and credit

Statistics are retrieved from the e-Stat API provided by Japan's Statistics
Bureau / Ministry of Internal Affairs and Communications. Applications that
redistribute this data must display the credit line required by the
[e-Stat Terms of Use](https://www.e-stat.go.jp/api/). This service uses the API
function of the government statistics portal site (e-Stat) but its content is
not guaranteed by the government.

## License

MIT © estatr authors

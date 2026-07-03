<!-- README.md is generated from README.Rmd. Please edit that file -->

# estatr

<!-- badges: start -->
[![R-CMD-check](https://github.com/seangriffin/estatr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/seangriffin/estatr/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/seangriffin/estatr/graph/badge.svg)](https://app.codecov.io/gh/seangriffin/estatr)
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

> **Status:** early development. The HTTP/auth layer and low-level
> `estat_stats_list()` are in place (roadmap M0–M1). Higher-level tidy wrappers
> (`get_estat()`, `search_estat()`) are still to come.

## Installation

``` r
# install.packages("pak")
pak::pak("seangriffin/estatr")
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

# Search the catalog for tables mentioning a keyword
tables <- estat_stats_list(searchWord = "労働力調査")
```

## Data source and credit

Statistics are retrieved from the e-Stat API provided by Japan's Statistics
Bureau / Ministry of Internal Affairs and Communications. Applications that
redistribute this data must display the credit line required by the
[e-Stat Terms of Use](https://www.e-stat.go.jp/api/). This service uses the API
function of the government statistics portal site (e-Stat) but its content is
not guaranteed by the government.

## License

MIT © estatr authors

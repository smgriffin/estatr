# List the curated e-Stat shortcut tables

Returns the built-in table of curated shortcuts used by
[`get_estat_curated()`](https://smgriffin.github.io/estatr/reference/get_estat_curated.md)
and the survey-specific helpers. Entries whose `statsDataId` is `NA` are
recognised names that have not yet been curated to a specific table.

## Usage

``` r
estat_curated_tables()
```

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`key`, `statsDataId`, `label_en`, and `label_ja` columns.

## Examples

``` r
estat_curated_tables()
#> # A tibble: 5 × 4
#>   key                  statsDataId label_en                             label_ja
#>   <chr>                <chr>       <chr>                                <chr>   
#> 1 labour_force_survey  0003005798  Labour Force Survey: population by … 労働力調査 就…
#> 2 family_income_survey 0002070001  Family Income and Expenditure Survey 家計調査 家計…
#> 3 regional_statistics  0000010106  Social & demographic statistics by … 社会・人口統計…
#> 4 population_census    0003433219  Population Census 2020: population … 令和2年国勢調…
#> 5 economic_census      0004005652  Economic Census 2021: establishment… 令和3年経済セ…
```

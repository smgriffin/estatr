# Japanese prefectures with JIS codes and e-Stat area codes

The 47 Japanese prefectures (都道府県) with their JIS X 0401 codes and
English/Japanese names, for joining and filtering e-Stat `area` codes
without another API round-trip. The e-Stat whole-prefecture `area` code
is the 2-digit JIS code followed by `"000"` (e.g. Tokyo = `"13000"`).

## Usage

``` r
prefectures
```

## Format

A tibble with 47 rows and 5 columns:

- code:

  2-digit JIS X 0401 prefecture code, e.g. `"13"`.

- area_code:

  5-digit e-Stat area code for the whole prefecture, e.g. `"13000"`.

- name_en:

  English (romaji) prefecture name, e.g. `"Tokyo"`.

- name_ja:

  Japanese prefecture name, e.g. `"東京都"`.

- region_en:

  English region name, e.g. `"Kanto"`.

## Source

JIS X 0401 (Japanese Industrial Standard) prefecture codes.

## Examples

``` r
head(prefectures)
#> # A tibble: 6 × 5
#>   code  area_code name_en  name_ja region_en
#>   <chr> <chr>     <chr>    <chr>   <chr>    
#> 1 01    01000     Hokkaido 北海道  Hokkaido 
#> 2 02    02000     Aomori   青森県  Tohoku   
#> 3 03    03000     Iwate    岩手県  Tohoku   
#> 4 04    04000     Miyagi   宮城県  Tohoku   
#> 5 05    05000     Akita    秋田県  Tohoku   
#> 6 06    06000     Yamagata 山形県  Tohoku   
# Join onto a get_estat() result by area_code to add English names
```

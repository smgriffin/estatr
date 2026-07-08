# Download e-Stat administrative boundaries as an sf object

Fetches official e-Stat census boundary polygons and returns them as an
sf object with an `area_code` column matching the codes used by
[`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md),
so the two join cleanly. Boundaries are derived from e-Stat's
authoritative small-area (町丁・字) shapefiles and dissolved to the
requested `level`.

## Usage

``` r
estat_boundaries(
  areas = NULL,
  level = c("municipality", "prefecture", "small_area"),
  year = 2020,
  datum = c("2000", "2011"),
  cache = TRUE,
  designated_cities = c("both", "ward", "city")
)
```

## Arguments

- areas:

  Character vector of area codes selecting which prefectures to
  download: 2-digit prefecture codes (e.g. `"31"`) or any codes whose
  first two digits are a prefecture (e.g. a 5-digit `"31201"` or the
  `area_code` column from
  [`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)).
  `NULL` downloads all 47 prefectures (large).

- level:

  Geographic level to return: `"municipality"` (default; 5-digit
  `PREF+CITY`) or `"prefecture"` (dissolved whole prefectures,
  `PREF+"000"`) or `"small_area"` (raw 町丁・字, 9-digit `KEY_CODE`).

- year:

  Census year of the boundaries (e.g. `2020`, `2015`). Match this to the
  census year of your data: municipality codes and boundaries change
  between censuses (mergers), so a mismatched year can mis-join.

- datum:

  Geodetic datum: `"2000"` (JGD2000, EPSG:4612, default) or `"2011"`
  (JGD2011, EPSG:6668).

- cache:

  If `TRUE` (default), cache downloaded boundary files under
  [`estat_cache_dir()`](https://smgriffin.github.io/estatr/reference/estat_cache_dir.md).

- designated_cities:

  How to handle the 20 ordinance-designated cities and Tokyo's special
  wards at `level = "municipality"`, since e-Stat's shapefiles carry
  only ward codes: `"both"` (default) returns ward polygons *and* a
  unioned parent-city polygon (e.g. both `01101`… and `01100` 札幌市),
  so data coded at either level joins; `"ward"` returns wards only;
  `"city"` returns the parent city only. Ignored for other levels.

## Value

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object with
`area_code`, name columns, and geometry.

## Details

Requires the sf package. Downloaded files are cached (see
[`estat_cache_dir()`](https://smgriffin.github.io/estatr/reference/estat_cache_dir.md)).

## Examples

``` r
if (FALSE) { # \dontrun{
# Municipalities of Tottori (prefecture 31), 2020 census boundaries
bnd <- estat_boundaries("31", level = "municipality", year = 2020)
} # }
```

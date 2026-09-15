# estatr

<!-- badges: start -->
[![R-CMD-check](https://github.com/smgriffin/estatr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/smgriffin/estatr/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/smgriffin/estatr/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/smgriffin/estatr/actions/workflows/pkgdown.yaml)
[![Codecov test coverage](https://codecov.io/gh/smgriffin/estatr/graph/badge.svg)](https://app.codecov.io/gh/smgriffin/estatr)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

📖 **Documentation:** <https://smgriffin.github.io/estatr/>

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
> caching, resumable pulls, and choropleth-ready boundary geometry are all in
> place.

## Contents

- [Installation](#installation)
- [Authentication](#authentication)
- [Quick start](#quick-start)
- [Finding a table](#finding-a-table)
- [Getting data](#getting-data)
- [Understanding the output](#understanding-the-output)
- [Curated shortcuts](#curated-shortcuts)
- [Inspecting a table's metadata](#inspecting-a-tables-metadata)
- [Filtering](#filtering)
- [Reshaping to wide form](#reshaping-to-wide-form)
- [Language: English and Japanese](#language-english-and-japanese)
- [Maps and boundary geometry](#maps-and-boundary-geometry)
- [Large pulls, pagination and resuming](#large-pulls-pagination-and-resuming)
- [Performance fast paths](#performance-fast-paths)
- [Caching](#caching)
- [Low-level API wrappers](#low-level-api-wrappers)
- [Function reference](#function-reference)

## Installation

``` r
# install.packages("pak")
pak::pak("smgriffin/estatr")
```

For maps you also need the suggested `sf` package:

``` r
install.packages("sf")
```

## Authentication

The e-Stat API requires a free `appId`. Sign up at
<https://www.e-stat.go.jp/api/> and issue an application ID, then register it:

``` r
library(estatr)

# Write the key to ~/.Renviron so future sessions pick it up automatically
estat_api_key("your-app-id", install = TRUE)

# Set it for this session only
estat_api_key("your-app-id")

# Check whether a key is already available
estat_api_key_exists()
#> [1] TRUE
```

`estatr` reads the key from the `ESTAT_API_KEY` environment variable, so you can
also set it in `.Renviron` yourself. The key is a secret: never commit it or
paste it into an issue. `estatr` redacts it from error messages and test
fixtures.

## Quick start

``` r
library(estatr)

# 1. Find a table
search_estat("Labour Force Survey", limit = 5)

# 2. Fetch it, decoded to labels
d <- get_estat("0003217721", limit = 500)

# 3. Or skip the id lookup entirely
d <- get_labour_force_survey(limit = 500)
```

## Finding a table

`search_estat()` is the interactive-friendly search. It renames e-Stat's raw
columns to stable snake_case and moves the useful ones to the front.

``` r
search_estat("Labour Force Survey", limit = 5)[, c("id", "statistics_name", "title", "cycle")]
#> # A tibble: 5 × 4
#>   id         statistics_name                                               title           cycle
#>   <chr>      <chr>                                                         <chr>           <chr>
#> 1 0000010106 Prefectural Data Basic Data                                   System of Soci… Fisc…
#> 2 0000010106 Prefectural Data Basic Data                                   System of Soci… Fisc…
#> 3 0003217721 Labour Force Survey Detailed Tabulation Whole Japan Quarterly Population of … Quar…
#> 4 0003217545 Labour Force Survey Detailed Tabulation Whole Japan Quarterly Labour underut… Quar…
#> 5 0003006357 Labour Force Survey Detailed Tabulation Whole Japan Quarterly Population of … Quar…
```

Japanese keywords work too, and you can restrict to recently updated tables:

``` r
search_estat("国勢調査")
search_estat("国勢調査", updated_from = "2020")
search_estat("Population Census", limit = 20)
```

The `id` column is the `statsDataId` you pass to `get_estat()`.

### Browsing the file catalog

`estat_data_catalog()` searches e-Stat's catalog of *downloadable files*
(Excel/CSV/PDF) rather than machine-readable data. Use it for discovery; use
`get_estat()` for the actual numbers.

``` r
estat_data_catalog(searchWord = "Population Census", limit = 3)[, c("id", "DATASET_TITLE_NAME")]
#> # A tibble: 3 × 2
#>   id           DATASET_TITLE_NAME
#>   <chr>        <chr>
#> 1 000000030001 2000 Population Census_Sex, Age and Marital Status of Population, Structure and …
#> 2 000000030097 2000 Population Census_Lobour Force Status of Population, Industry(Major Groups)…
#> 3 000000030587 2000 Population Census_Final Report of The 2000 Population Census_Statistical ta…
```

## Getting data

`get_estat()` is the main entry point. It fetches the data *and* its
classification metadata in a single call, decodes every numeric code to a label,
and returns a tidy tibble.

``` r
d <- get_estat("0003217721", limit = 5)
d[, c("area", "time", "cat01", "unit", "value")]
#> # A tibble: 5 × 5
#>   area      time           cat01                                 unit                 value
#>   <chr>     <chr>          <chr>                                 <chr>                <dbl>
#> 1 All Japan Jan.-Mar. 2018 Population aged 15 years old and over ten thousand persons 11077
#> 2 All Japan Apr.-Jun. 2018 Population aged 15 years old and over ten thousand persons 11079
#> 3 All Japan Jul.-Sep. 2018 Population aged 15 years old and over ten thousand persons 11079
#> 4 All Japan Oct.-Dec. 2018 Population aged 15 years old and over ten thousand persons 11080
#> 5 All Japan Jan.-Mar. 2019 Population aged 15 years old and over ten thousand persons 11068
```

Omit `limit` to fetch every matching row; `estatr` paginates automatically.

## Understanding the output

Every classification axis comes back as a **pair** of columns: the decoded label
and the original code.

``` r
names(get_estat("0003217721", limit = 5))
#>  [1] "area"   "area_code"  "time"   "time_code"  "tab"    "tab_code"
#>  [7] "cat01"  "cat01_code" "cat02"  "cat02_code" "cat03"  "cat03_code"
#> [13] "cat04"  "cat04_code" "unit"   "value"      "annotation"
```

- `area` / `area_code` — geography (`area_code` is what maps join on)
- `time` / `time_code` — period
- `tab`, `cat01`…`cat04` — the table's category axes
- `unit` — unit of measurement
- `value` — **numeric**
- `annotation` — non-numeric markers preserved instead of silently becoming `NA`

### Annotations, not silent NAs

e-Stat uses markers like `-`, `***` and `*` for suppressed or inapplicable
cells. `estatr` keeps them:

``` r
e <- get_estat("0004005652", limit = 8000)
head(e[!is.na(e$annotation), c("area", "cat01", "value", "annotation")], 3)
#> # A tibble: 3 × 4
#>   area         cat01                               value annotation
#>   <chr>        <chr>                               <dbl> <chr>
#> 1 Saitama-shi  Agriculture, Forestry and Fisheries    NA -
#> 2 Kawasaki-shi Agriculture, Forestry and Fisheries    NA -
#> 3 Niigata-shi  Agriculture, Forestry and Fisheries    NA -
```

The legend for those markers travels with the data as a `notes` attribute:

``` r
attr(e, "notes")
#> # A tibble: 3 × 2
#>   char  note
#>   <chr> <chr>
#> 1 *     Shortened item name
#> 2 ***   The one that figure is not obtained
#> 3 -     Not applicable
```

## Curated shortcuts

For the handful of tables most people want first, you don't need an id at all.

``` r
estat_curated_tables()
#> # A tibble: 5 × 4
#>   key                  statsDataId label_en                                         label_ja
#>   <chr>                <chr>       <chr>                                            <chr>
#> 1 labour_force_survey  0003005798  Labour Force Survey: population by activity      労働力調査…
#> 2 family_income_survey 0002070001  Family Income and Expenditure Survey             家計調査…
#> 3 regional_statistics  0000010106  Social & demographic statistics by prefecture    社会・人口…
#> 4 population_census    0003433219  Population Census 2020: population by sex        令和2年国勢…
#> 5 economic_census      0004005652  Economic Census 2021: establishments by industry 令和3年経済…
```

Each has a dedicated wrapper, and all of them forward `...` to `get_estat()`:

``` r
get_labour_force_survey(limit = 500)
get_population_census(cdArea = "13000")          # Tokyo
get_family_income_survey(limit = 500)
get_economic_census(limit = 500)

# Or by key
get_estat_curated("population_census", limit = 500)
```

## Inspecting a table's metadata

Before pulling a big table, look at what axes and codes it has. This is how you
learn which `cd*` filter values are valid.

``` r
m <- estat_meta_info("0003433219")
names(m)
#> [1] "tab"   "cat01" "area"  "time"

m$cat01
#> # A tibble: 3 × 5
#>   code  name   level unit  parent
#>   <chr> <chr>  <chr> <chr> <chr>
#> 1 0     Total  1     <NA>  <NA>
#> 2 1     Male   1     <NA>  <NA>
#> 3 2     Female 1     <NA>  <NA>

head(m$area, 3)
#> # A tibble: 3 × 5
#>   code  name        level parent unit
#>   <chr> <chr>       <chr> <chr>  <chr>
#> 1 00000 Japan       1     <NA>   <NA>
#> 2 01000 Hokkaido    2     00000  <NA>
#> 3 01100 Sapporo-shi 4     01000  <NA>
```

The `level` and `parent` columns describe the hierarchy — national → prefecture
→ city → ward.

## Filtering

Any `cd*` parameter from the e-Stat API passes straight through `...`:

``` r
# One category, from 2023 onward
get_estat("0003217721", cdCat01 = "00", cdTimeFrom = "2023000000", limit = 6)[, c("area", "time", "cat01", "value")]
#> # A tibble: 6 × 4
#>   area      time           cat01                                 value
#>   <chr>     <chr>          <chr>                                 <dbl>
#> 1 All Japan Jan.-Mar. 2023 Population aged 15 years old and over 10993
#> 2 All Japan Apr.-Jun. 2023 Population aged 15 years old and over 11002
#> 3 All Japan Jul.-Sep. 2023 Population aged 15 years old and over 11002
#> 4 All Japan Oct.-Dec. 2023 Population aged 15 years old and over 10989
#> 5 All Japan Jan.-Mar. 2024 Population aged 15 years old and over 10976
#> 6 All Japan Apr.-Jun. 2024 Population aged 15 years old and over 10978
```

Common filters:

``` r
get_estat("0003433219", cdArea = "13000")                    # one area
get_estat("0003433219", cdArea = c("13000", "27000"))        # several areas
get_estat("0003433219", cdCat01 = "1")                       # one category
get_estat("0003217721", cdTime = "2023000103")               # one period
get_estat("0003217721", cdTimeFrom = "2020000000",
                        cdTimeTo   = "2023000000")           # a period range
```

## Reshaping to wide form

``` r
p  <- get_estat("0003433219")
pp <- p[grepl("000$", p$area_code) & p$area_code != "00000", ]   # prefectures only

w <- pivot_estat_wide(pp, names_from = "cat01", values_from = "value")
head(w[, c("area", "area_code", "Total", "Male", "Female")], 5)
#> # A tibble: 5 × 5
#>   area       area_code   Total    Male  Female
#>   <chr>      <chr>       <dbl>   <dbl>   <dbl>
#> 1 Aichi-ken  23000     7546192 3762249 3783943
#> 2 Akita-ken  05000      960113  452479  507634
#> 3 Aomori-ken 02000     1238730  583541  655189
#> 4 Chiba-ken  12000     6287034 3117871 3169163
#> 5 Ehime-ken  38000     1335694  633220  702474
```

## Language: English and Japanese

`estatr` works in **English by default** — e-Stat provides the translations.

``` r
get_estat("0003217721", limit = 2, lang = "J")[, c("area", "time", "cat01", "unit")]
#> # A tibble: 2 × 4
#>   area  time           cat01        unit
#>   <chr> <chr>          <chr>        <chr>
#> 1 全国  2018年1～3月期 15歳以上人口 万人
#> 2 全国  2018年4～6月期 15歳以上人口 万人
```

Set it globally for a session:

``` r
options(estatr.lang = "J")
```

Tables with no English release fall back to Japanese automatically and warn, so
English mode never returns blanks:

```
#> Warning: This table has no English release from e-Stat; returning Japanese labels.
#> ℹ Pass `lang = "J"` to request Japanese directly and silence this warning.
```

## Maps and boundary geometry

`estatr` downloads official e-Stat census boundary polygons and joins them on
`area_code`, giving you a choropleth-ready `sf` object. Requires `sf`.

The shortcut is `geometry = TRUE` on `get_estat()`:

``` r
library(sf)

pop <- get_estat("0003433219", cdCat01 = "0", lvArea = "2", geometry = TRUE,
                 geometry_level = "prefecture", geometry_year = 2020)

nrow(pop)
#> [1] 47

plot(pop["value"])
```

Or join geometry onto data you already have:

``` r
d   <- get_population_census(cdCat01 = "0", lvArea = "2")
map <- estat_join_geometry(d, level = "prefecture", year = 2020)
```

### Ask for one geographic level

That `lvArea = "2"` matters. Most e-Stat tables stack every geography in one
table — national total, prefectures, municipalities, wards. `0003433219` holds
**1,965 areas**. Fetch all of them and join at `level = "prefecture"` and only
47 get a polygon; the rest come back with empty geometry and a warning.

e-Stat's `lv<axis>` parameters filter by level server-side, and pass straight
through `...`:

``` r
nrow(get_estat("0003433219", cdCat01 = "0"))              # every level
#> [1] 1965
nrow(get_estat("0003433219", cdCat01 = "0", lvArea = "2"))  # prefectures only
#> [1] 47
```

For this table the levels are `1` national, `2` prefecture, `4` city, `5` ward,
`6` town/village. They vary by table, so check the `level` and `parent` columns
of `estat_meta_info(id)$area` rather than assuming. The same works for other
axes (`lvCat01`, `lvTime`, …).

With `ggplot2`:

``` r
library(ggplot2)

ggplot(map) +
  geom_sf(aes(fill = value)) +
  scale_fill_viridis_c(trans = "log10") +
  theme_void()
```

### Downloading boundaries on their own

``` r
b <- estat_boundaries("31", level = "municipality", year = 2020)   # Tottori
b[1:4, c("area_code", "CITY_NAME")]
#> Simple feature collection with 4 features and 2 fields
#> Geometry type: GEOMETRY
#> Bounding box:  xmin: 133.1984 ymin: 35.27164 xmax: 134.4408 ymax: 35.57287
#> Geodetic CRS:  JGD2000
#>   area_code CITY_NAME                       geometry
#> 1     31201    鳥取市 MULTIPOLYGON (((134.0244 35...
#> 2     31202    米子市 POLYGON ((133.343 35.38851,...
#> 3     31203    倉吉市 POLYGON ((133.7687 35.31787...
#> 4     31204    境港市 POLYGON ((133.2347 35.48433...
```

Three levels are available, all derived from the same authoritative small-area
shapefiles so the codes always match your data:

``` r
estat_boundaries("31", level = "prefecture")    # whole prefectures, PREF + "000"
estat_boundaries("31", level = "municipality")  # 5-digit PREF + CITY (default)
estat_boundaries("31", level = "small_area")    # raw 町丁・字, 9-digit KEY_CODE
```

Notes worth knowing:

- **Match `year` to your data's census year.** Municipality codes change between
  censuses (mergers), so a mismatched year mis-joins. `estat_join_geometry()`
  warns about codes it could not match.
- **Boundary name columns are Japanese only** (`PREF_NAME`, `CITY_NAME`) — the
  shapefiles ship no English. Your `get_estat()` labels are still English.
- **The national total (`00000`) has no polygon.** It is kept with an empty
  geometry rather than dropped, so row counts line up with the input.
- **Designated cities:** e-Stat's shapefiles carry only ward codes. The default
  `designated_cities = "both"` returns ward polygons *and* a unioned parent-city
  polygon, so data coded at either level joins. Use `"ward"` or `"city"` to pick
  one.
- Downloads are cached, and all 47 prefectures is roughly 250 MB — pass `areas`
  to fetch only what you need.

``` r
estat_boundaries(c("13", "14"), level = "municipality")   # Tokyo + Kanagawa
estat_boundaries("13", designated_cities = "ward")        # special wards only
estat_boundaries("13", year = 2015, datum = "2011")       # JGD2011 (2015/2020 only)
```

## Large pulls, pagination and resuming

e-Stat caps a single response at 100,000 records. `get_estat()` paginates
automatically, fetching pages in parallel with bounded concurrency and a polite
client-side throttle.

``` r
d <- get_estat("0003217721")   # 42,751 rows, fetched in a few seconds
nrow(d)
#> [1] 42751
```

For very large pulls, `checkpoint` makes the job resumable — rerun the same call
after an interruption and it picks up where it left off:

``` r
d <- get_estat("0003433219", checkpoint = "census2020.rds")
```

Tune the network behaviour with options:

``` r
options(estatr.throttle   = 0.34)  # min seconds between requests (default)
options(estatr.max_active = 5)     # max concurrent requests
options(estatr.timeout    = 60)    # per-request timeout, seconds
```

## Performance fast paths

Internals use `data.table`; the tibble conversion happens only at the return
boundary. Two escape hatches for bulk work:

``` r
# Skip the metadata join entirely — coded columns only
get_estat("0003217721", limit = 3, decode_labels = FALSE)
#> # A tibble: 3 × 10
#>   tab   cat01 cat02 cat03 cat04 area  time       unit                 value annotation
#>   <chr> <chr> <chr> <chr> <chr> <chr> <chr>      <chr>                <dbl> <chr>
#> 1 06    00    00    0     00    00000 2018000103 ten thousand persons 11077 <NA>
#> 2 06    00    00    0     00    00000 2018000406 ten thousand persons 11079 <NA>
#> 3 06    00    00    0     00    00000 2018000709 ten thousand persons 11079 <NA>

# Return the data.table directly, skipping even the tibble conversion
dt <- get_estat("0003217721", as_data_table = TRUE)
```

## Caching

Classification metadata is cached on disk (with an in-session memoise layer on
top), and boundary downloads are cached too.

``` r
estat_cache_dir()
#> [1] "~/Library/Caches/estatr"

estat_cache_clear()                    # everything
estat_cache_clear("meta")              # metadata only
estat_cache_clear("checkpoints")       # resumable-pull checkpoints only

options(estatr.cache_dir = "~/my-cache")   # relocate the cache
```

## Low-level API wrappers

If you want the API surface as-is, each endpoint has a thin wrapper. These
mirror e-Stat's own parameter and column names.

``` r
# getStatsList — raw catalog search
estat_stats_list(searchWord = "Economic Census", limit = 3)[, c("id", "STATISTICS_NAME", "CYCLE")]
#> # A tibble: 3 × 3
#>   id         STATISTICS_NAME                                            CYCLE
#>   <chr>      <chr>                                                      <chr>
#> 1 0000010103 Prefectural Data Basic Data                                Fiscal yearly
#> 2 0000010103 Prefectural Data Basic Data                                Fiscal yearly
#> 3 0000020103 Municipality data Basic data including past municipalities Fiscal yearly

# getStatsData — undecoded values
estat_stats_data("0003217721", limit = 3)
#> # A tibble: 3 × 9
#>   tab   cat01 cat02 cat03 cat04 area  time       unit                 value
#>   <chr> <chr> <chr> <chr> <chr> <chr> <chr>      <chr>                <chr>
#> 1 06    00    00    0     00    00000 2018000103 ten thousand persons 11077
#> 2 06    00    00    0     00    00000 2018000406 ten thousand persons 11079
#> 3 06    00    00    0     00    00000 2018000709 ten thousand persons 11079

# getMetaInfo — classification metadata
estat_meta_info("0003217721")

# getDataCatalog — downloadable file catalog
estat_data_catalog(searchWord = "国勢調査", limit = 10)
```

Note that `estat_stats_data()` returns `value` as **character** (undecoded);
`get_estat()` is what splits it into a numeric `value` plus `annotation`.

## Function reference

| Function | Purpose |
| --- | --- |
| `get_estat()` | Main entry point: tidy, labelled data |
| `search_estat()` | Interactive catalog search |
| `estat_meta_info()` | A table's classification axes and codes |
| `pivot_estat_wide()` | Reshape tidy output to wide form |
| `estat_curated_tables()` | List the curated shortcut tables |
| `get_estat_curated()` | Fetch a curated table by key |
| `get_labour_force_survey()` | Curated: Labour Force Survey |
| `get_population_census()` | Curated: Population Census 2020 |
| `get_family_income_survey()` | Curated: Family Income and Expenditure Survey |
| `get_economic_census()` | Curated: Economic Census 2021 |
| `estat_boundaries()` | Download boundary polygons as `sf` |
| `estat_join_geometry()` | Join polygons onto e-Stat data |
| `estat_api_key()` | Register your appId |
| `estat_api_key_exists()` | Check for a registered key |
| `estat_cache_dir()` | Where the cache lives |
| `estat_cache_clear()` | Clear cached metadata/checkpoints |
| `estat_stats_list()` | Low-level `getStatsList` |
| `estat_stats_data()` | Low-level `getStatsData` |
| `estat_data_catalog()` | Low-level `getDataCatalog` |

See `vignette("estatr")` for a longer walkthrough.

## Data source and credit

Statistics are retrieved from the e-Stat API provided by Japan's Statistics
Bureau / Ministry of Internal Affairs and Communications. Applications that
redistribute this data must display the credit line required by the
[e-Stat Terms of Use](https://www.e-stat.go.jp/api/). This service uses the API
function of the government statistics portal site (e-Stat) but its content is
not guaranteed by the government.

## License

MIT © estatr authors

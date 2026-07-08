# Mapping e-Stat data (choropleths)

`estatr` can attach official e-Stat boundary polygons to your data so
you can draw choropleth maps. Geometry comes from e-Stat’s own census
boundary files, which are keyed to the **same area codes** as the
statistics — so the join is exact, by construction. This needs the
[sf](https://r-spatial.github.io/sf/) package.

## The one-call path

Pass `geometry = TRUE` to \[get_estat()\] and you get an `sf` object
back:

``` r

library(sf)
library(ggplot2)

pop <- get_estat(
  "0003433219",             # 2020 Population Census, population by sex
  cdCat01 = "0",            # total (both sexes)
  geometry = TRUE,
  geometry_level = "prefecture",
  geometry_year = 2020
)

ggplot(pop) +
  geom_sf(aes(fill = value)) +
  scale_fill_viridis_c(trans = "log10") +
  labs(title = "Population by prefecture, 2020", fill = "People")
```

## Attaching geometry to data you already have

If you already pulled data, join geometry separately with
\[estat_join_geometry()\]:

``` r

d <- get_estat("0003433219", cdCat01 = "0")
sf_d <- estat_join_geometry(d, level = "prefecture", year = 2020)
```

## Levels

`level` (or `geometry_level`) controls the geography:

- `"prefecture"` — 47 prefectures (`area_code` ending in `000`).
- `"municipality"` — cities/wards/towns/villages (5-digit `area_code`).
- `"small_area"` — town-block (町丁・字), the raw 9-digit `KEY_CODE`.
- `"auto"` — prefecture if every `area_code` ends in `000`, else
  municipality.

Boundaries are downloaded per prefecture and cached (see
\[estat_cache_dir()\]), so a municipality map of one prefecture only
fetches that prefecture’s file.

## Matching the boundary year to your data

**This matters for accuracy.** Japanese municipality codes and
boundaries change between censuses (mergers and dissolutions), so set
`geometry_year` to the census year of your data. Joining 2020 data to
2015 boundaries can silently drop or mis-place municipalities that
changed in between.

## Coordinate system

Boundaries come in JGD2000 (`datum = "2000"`, EPSG:4612, the default) or
JGD2011 (`datum = "2011"`, EPSG:6668). Reproject as needed for your
basemap, e.g. to a projected CRS for area-correct rendering:

``` r

pop_proj <- sf::st_transform(pop, 6684) # JGD2011 / Japan Plane Rectangular CS
```

## Designated cities and known limitations

For ordinance-designated cities (政令指定都市) and Tokyo, e-Stat’s
boundary files use **ward** codes (e.g. Sapporo’s wards
`01101`–`01110`), not the parent-city code (`01100`) — but e-Stat
*statistics* report these cities at both levels. By default
(`designated_cities = "both"`), `estatr` returns both the ward polygons
*and* a unioned parent-city polygon, so data coded either way joins with
no holes:

``` r

# Sapporo appears as its 10 wards AND as 01100 札幌市 (union of the wards)
bnd <- estat_boundaries("01", level = "municipality", year = 2020)
```

Use `designated_cities = "ward"` for wards only, or `"city"` to replace
each designated city’s wards with just the parent-city polygon. The same
argument is available on
[`estat_join_geometry()`](https://smgriffin.github.io/estatr/reference/estat_join_geometry.md)
and as `geometry_designated_cities` in
[`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md).
Any code that still finds no polygon triggers a warning rather than a
silent gap.

Note also e-Stat’s own disclaimer: these boundaries are drawn for
statistical tabulation and do not necessarily coincide with legal
administrative borders.

## Attribution

Boundary data is from e-Stat (統計地理情報システム). Maps you publish
must carry the e-Stat credit line; see the [e-Stat Terms of
Use](https://www.e-stat.go.jp/api/).

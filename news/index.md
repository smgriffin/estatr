# Changelog

## estatr 0.0.0.9000

First development release: a tidy, tidycensus-style interface to the
Japanese e-Stat API, covering roadmap milestones M0–M6.

### Language

- Works in **English by default**: table names, category/area/time
  labels, and search all return in English (e-Stat provides the
  translations). Control it per call with `lang = "E"` / `"J"`, or
  globally with `options(estatr.lang = )`.
- Tables that have no English release fall back to Japanese
  automatically, with a warning, so English mode never errors or returns
  blanks.

### High-level data access

- [`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md):
  the main entry point. Fetches data and its classification metadata in
  a single call, decodes every numeric code to a label via `data.table`
  binary joins, and returns a tidy tibble with paired label/code columns
  (e.g. `area` + `area_code`, `time` + `time_code`), `unit`, a numeric
  `value`, and an `annotation` column that preserves non-numeric markers
  (suppressed cells, footnotes) instead of coercing them silently to
  `NA`. The table’s annotation legend is attached as a `notes`
  attribute. Fast paths: `decode_labels = FALSE` and
  `as_data_table = TRUE`.
- [`pivot_estat_wide()`](https://smgriffin.github.io/estatr/reference/pivot_estat_wide.md):
  reshape tidy output to wide form
  ([`data.table::dcast`](https://rdrr.io/pkg/data.table/man/dcast.data.table.html)).

### Discovery

- [`search_estat()`](https://smgriffin.github.io/estatr/reference/search_estat.md):
  friendly catalog search with stable snake_case columns.
- Curated shortcuts —
  [`estat_curated_tables()`](https://smgriffin.github.io/estatr/reference/estat_curated_tables.md),
  [`get_estat_curated()`](https://smgriffin.github.io/estatr/reference/get_estat_curated.md),
  [`get_labour_force_survey()`](https://smgriffin.github.io/estatr/reference/get_labour_force_survey.md),
  [`get_family_income_survey()`](https://smgriffin.github.io/estatr/reference/get_family_income_survey.md),
  [`get_population_census()`](https://smgriffin.github.io/estatr/reference/get_population_census.md),
  [`get_economic_census()`](https://smgriffin.github.io/estatr/reference/get_economic_census.md)
  — so common tables need no `statsDataId` lookup.
- `prefectures`: bundled reference data (47 prefectures, JIS + e-Stat
  area codes, English/Japanese names).

### Low-level endpoint wrappers

- [`estat_stats_list()`](https://smgriffin.github.io/estatr/reference/estat_stats_list.md)
  (getStatsList),
  [`estat_meta_info()`](https://smgriffin.github.io/estatr/reference/estat_meta_info.md)
  (getMetaInfo),
  [`estat_stats_data()`](https://smgriffin.github.io/estatr/reference/estat_stats_data.md)
  (getStatsData),
  [`estat_data_catalog()`](https://smgriffin.github.io/estatr/reference/estat_data_catalog.md)
  (getDataCatalog).
- [`estat_stats_data()`](https://smgriffin.github.io/estatr/reference/estat_stats_data.md)
  paginates automatically, fetching pages beyond the 100,000-record cap
  concurrently by absolute offset (“parallel but polite”, bounded and
  throttled) rather than leaving pagination to the user.

### Infrastructure

- [`estat_api_key()`](https://smgriffin.github.io/estatr/reference/estat_api_key.md)
  /
  [`estat_api_key_exists()`](https://smgriffin.github.io/estatr/reference/estat_api_key_exists.md):
  key management via environment variable and optional `.Renviron`; the
  key is never stored in package state or printed, and is redacted from
  every error message, URL, and fixture.
- Robust HTTP layer: JSON endpoints by default, UTF-8 query encoding,
  gzip, transient-only retry, and client-side throttling. e-Stat’s
  `RESULT.STATUS` is treated as the source of truth, with errors mapped
  to classed conditions (`estat_error_invalid_param`,
  `estat_error_no_data`, …).
- Caching: on-disk metadata cache with TTL
  ([`estat_cache_dir()`](https://smgriffin.github.io/estatr/reference/estat_cache_dir.md),
  [`estat_cache_clear()`](https://smgriffin.github.io/estatr/reference/estat_cache_clear.md))
  layered over in-session memoisation.
- Resumable pulls: pass `checkpoint =` to
  [`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)
  /
  [`estat_stats_data()`](https://smgriffin.github.io/estatr/reference/estat_stats_data.md)
  to persist completed page offsets, so an interrupted large pull
  resumes by re-requesting only the missing pages.

### Geometry / mapping

- `get_estat(geometry = TRUE)` returns an `sf` object with official
  e-Stat boundary polygons joined on `area_code`, ready for choropleth
  mapping.
- [`estat_boundaries()`](https://smgriffin.github.io/estatr/reference/estat_boundaries.md)
  downloads and dissolves e-Stat census boundaries to the prefecture,
  municipality, or small-area (町丁・字) level;
  [`estat_join_geometry()`](https://smgriffin.github.io/estatr/reference/estat_join_geometry.md)
  attaches them to an existing
  [`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)
  result. Boundaries are cached, read with the correct Shift-JIS
  encoding and JGD2000/2011 CRS, and repaired with
  [`st_make_valid()`](https://r-spatial.github.io/sf/reference/valid.html).
  Requires the suggested package. Match the boundary `year` to your
  data’s census year, since municipality codes change between censuses.
- Designated cities (政令指定都市) and Tokyo’s special wards: e-Stat’s
  shapefiles carry only ward codes, but its statistics report at both
  ward and parent-city level. `designated_cities = "both"` (the default)
  returns both the ward polygons and a unioned parent-city polygon
  (e.g. `01101`… and `01100` 札幌市), so data coded at either level
  joins without holes; `"ward"` and `"city"` select one or the other.

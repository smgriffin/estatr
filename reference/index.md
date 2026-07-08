# Package index

## Get data

High-level, analysis-ready access with decoded labels.

- [`get_estat()`](https://smgriffin.github.io/estatr/reference/get_estat.md)
  : Get tidy, labelled data from e-Stat
- [`pivot_estat_wide()`](https://smgriffin.github.io/estatr/reference/pivot_estat_wide.md)
  : Pivot tidy e-Stat output to wide form

## Geometry / mapping

Official e-Stat boundary polygons for choropleth maps (needs sf).

- [`estat_boundaries()`](https://smgriffin.github.io/estatr/reference/estat_boundaries.md)
  : Download e-Stat administrative boundaries as an sf object
- [`estat_join_geometry()`](https://smgriffin.github.io/estatr/reference/estat_join_geometry.md)
  : Attach boundary geometry to e-Stat data

## Discovery

Find the table you need.

- [`search_estat()`](https://smgriffin.github.io/estatr/reference/search_estat.md)
  : Search the e-Stat catalog (interactive-friendly)
- [`estat_curated_tables()`](https://smgriffin.github.io/estatr/reference/estat_curated_tables.md)
  : List the curated e-Stat shortcut tables
- [`get_estat_curated()`](https://smgriffin.github.io/estatr/reference/get_estat_curated.md)
  : Get a curated e-Stat table by name
- [`get_labour_force_survey()`](https://smgriffin.github.io/estatr/reference/get_labour_force_survey.md)
  : Get the Labour Force Survey (basic tabulation)
- [`get_family_income_survey()`](https://smgriffin.github.io/estatr/reference/get_family_income_survey.md)
  : Get the Family Income and Expenditure Survey
- [`get_population_census()`](https://smgriffin.github.io/estatr/reference/get_population_census.md)
  : Get the Population Census (population by sex)
- [`get_economic_census()`](https://smgriffin.github.io/estatr/reference/get_economic_census.md)
  : Get the Economic Census (establishments by industry)

## Low-level endpoint wrappers

Thin wrappers over the e-Stat API endpoints, for power users.

- [`estat_stats_list()`](https://smgriffin.github.io/estatr/reference/estat_stats_list.md)
  : Search the e-Stat catalog for statistical tables
- [`estat_meta_info()`](https://smgriffin.github.io/estatr/reference/estat_meta_info.md)
  : Retrieve classification metadata for an e-Stat table
- [`estat_stats_data()`](https://smgriffin.github.io/estatr/reference/estat_stats_data.md)
  : Retrieve statistical data values from e-Stat
- [`estat_data_catalog()`](https://smgriffin.github.io/estatr/reference/estat_data_catalog.md)
  : Search the e-Stat data catalog for datasets and files

## Authentication

- [`estat_api_key()`](https://smgriffin.github.io/estatr/reference/estat_api_key.md)
  : Set your e-Stat API key
- [`estat_api_key_exists()`](https://smgriffin.github.io/estatr/reference/estat_api_key_exists.md)
  : Is an e-Stat API key available?

## Caching

- [`estat_cache_dir()`](https://smgriffin.github.io/estatr/reference/estat_cache_dir.md)
  : Location of the estatr cache
- [`estat_cache_clear()`](https://smgriffin.github.io/estatr/reference/estat_cache_clear.md)
  : Clear the estatr cache

## Reference data

- [`prefectures`](https://smgriffin.github.io/estatr/reference/prefectures.md)
  : Japanese prefectures with JIS codes and e-Stat area codes

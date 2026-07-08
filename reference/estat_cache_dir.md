# Location of the estatr cache

Returns the directory estatr uses for cached metadata and pagination
checkpoints. Override with `options(estatr.cache_dir = "...")`.

## Usage

``` r
estat_cache_dir()
```

## Value

A file path (character scalar). The directory is created on demand.

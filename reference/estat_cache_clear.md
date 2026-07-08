# Clear the estatr cache

Removes cached metadata and/or pagination checkpoints from
[`estat_cache_dir()`](https://smgriffin.github.io/estatr/reference/estat_cache_dir.md).

## Usage

``` r
estat_cache_clear(what = c("all", "meta", "checkpoints"))
```

## Arguments

- what:

  Which caches to clear: `"meta"`, `"checkpoints"`, or `"all"`
  (default).

## Value

Invisibly, the number of files removed.

## Examples

``` r
if (FALSE) { # \dontrun{
estat_cache_clear()
} # }
```

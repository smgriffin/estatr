# Package-level mutable state (kept minimal): holds the in-session memoised
# metadata fetcher so repeated getMetaInfo calls for the same table within one
# session skip even the on-disk cache read.
.estatr <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .estatr$fetch_meta <- memoise::memoise(fetch_meta_tables)
}

# Fetch metadata tables through the in-session memoise layer. Falls back to a
# direct call if .onLoad hasn't run (e.g. under pkgload during tests).
memo_fetch_meta_tables <- function(statsDataId, key = get_estat_key()) {
  fn <- .estatr$fetch_meta
  if (is.null(fn)) {
    fn <- memoise::memoise(fetch_meta_tables)
    .estatr$fetch_meta <- fn
  }
  fn(statsDataId, key)
}

# On-disk caching for metadata, plus the checkpoint store for resumable pulls.
#
# Classification metadata rarely changes, so re-fetching it on every call is
# wasteful (the same rationale as tigris's shapefile cache). Metadata tables are
# cached to a user cache dir with a TTL; an in-session memoise layer (see
# .onLoad) skips even disk I/O for repeated ids within one session.

#' Location of the estatr cache
#'
#' Returns the directory estatr uses for cached metadata and pagination
#' checkpoints. Override with `options(estatr.cache_dir = "...")`.
#'
#' @return A file path (character scalar). The directory is created on demand.
#' @export
estat_cache_dir <- function() {
  dir <- getOption("estatr.cache_dir", rappdirs::user_cache_dir("estatr"))
  dir
}

# Ensure a cache subdirectory exists and return its path.
cache_subdir <- function(sub) {
  dir <- file.path(estat_cache_dir(), sub)
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

# Read a cached value by key if present and fresh (mtime within ttl seconds),
# otherwise NULL.
cache_get <- function(key, sub = "meta", ttl = Inf) {
  path <- file.path(cache_subdir(sub), paste0(key, ".rds"))
  if (!file.exists(path)) return(NULL)
  age <- as.numeric(difftime(Sys.time(), file.mtime(path), units = "secs"))
  if (is.finite(ttl) && age > ttl) return(NULL)
  tryCatch(readRDS(path), error = function(e) NULL)
}

# Write a value to the cache atomically (write to a temp file, then rename) so an
# interrupted write can't leave a half-written cache entry.
cache_set <- function(key, value, sub = "meta") {
  path <- file.path(cache_subdir(sub), paste0(key, ".rds"))
  tmp <- paste0(path, ".tmp-", Sys.getpid())
  saveRDS(value, tmp)
  file.rename(tmp, path)
  invisible(path)
}

#' Clear the estatr cache
#'
#' Removes cached metadata and/or pagination checkpoints from [estat_cache_dir()].
#'
#' @param what Which caches to clear: `"meta"`, `"checkpoints"`, or `"all"`
#'   (default).
#' @return Invisibly, the number of files removed.
#' @export
#' @examples
#' \dontrun{
#' estat_cache_clear()
#' }
estat_cache_clear <- function(what = c("all", "meta", "checkpoints")) {
  what <- rlang::arg_match(what)
  subs <- if (identical(what, "all")) c("meta", "checkpoints") else what
  removed <- 0L
  for (sub in subs) {
    dir <- file.path(estat_cache_dir(), sub)
    if (dir.exists(dir)) {
      files <- list.files(dir, full.names = TRUE)
      removed <- removed + sum(file.remove(files))
    }
  }
  # Also reset the in-session memoise cache so cleared metadata is re-fetched.
  fn <- .estatr$fetch_meta
  if (!is.null(fn) && memoise::is.memoised(fn)) memoise::forget(fn)
  cli::cli_inform("Removed {removed} cached file{?s}.")
  invisible(removed)
}

# A stable cache key for a table's metadata (keyed by language, since labels
# differ between English and Japanese).
meta_cache_key <- function(statsDataId, lang = "E") paste0("meta-", lang, "-", statsDataId)

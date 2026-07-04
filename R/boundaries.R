# Boundary geometry from e-Stat's official GIS boundary data service.
#
# e-Stat publishes census small-area (町丁・字) boundary shapefiles keyed to the
# same area codes as its statistical data, per census year. Deriving every level
# (municipality, prefecture) from that one authoritative small-area source keeps
# geometry codes guaranteed-consistent with the data you join them to.
#
# Verified against real 2020 downloads (see the download URL below):
#   * CRS: coordSys=1 -> JGD2000 geographic = EPSG:4612 (the .prj carries no EPSG
#     code, so we assign it); datum=2011 -> JGD2011 = EPSG:6668.
#   * The .dbf is Shift-JIS/CP932, NOT UTF-8 -- must be read with that encoding.
#   * Codes: PREF(2) + CITY(3) = the 5-digit municipality code; KEY_CODE(9) =
#     PREF + CITY + S_AREA(4). So municipality = dissolve by PREF+CITY,
#     prefecture = dissolve by PREF.
#   * e-Stat polygons contain occasional invalid rings -> st_make_valid() on read.

estat_boundary_base_url <- function() "https://www.e-stat.go.jp/gis/statmap-search/data"

# EPSG code for a given datum choice.
boundary_epsg <- function(datum) if (identical(datum, "2011")) 6668L else 4612L

# Census years e-Stat publishes 町丁・字 boundaries for, and the subset that also
# offers a JGD2011 (datum=2011) variant.
estat_boundary_years <- c(2000, 2005, 2010, 2015, 2020)
estat_boundary_datum2011_years <- c(2015, 2020)

validate_boundary_year_datum <- function(year, datum) {
  if (!year %in% estat_boundary_years) {
    cli::cli_abort(
      "e-Stat has no {.arg year} {year} boundaries. Available: {estat_boundary_years}.",
      class = "estat_error_invalid_arg"
    )
  }
  if (identical(datum, "2011") && !year %in% estat_boundary_datum2011_years) {
    cli::cli_abort(
      c(
        "{.code datum = \"2011\"} (JGD2011) is only available for {estat_boundary_datum2011_years}.",
        "i" = 'Use {.code datum = "2000"} for {year}.'
      ),
      class = "estat_error_invalid_arg"
    )
  }
  invisible()
}

#' Download e-Stat administrative boundaries as an sf object
#'
#' Fetches official e-Stat census boundary polygons and returns them as an
#' \pkg{sf} object with an `area_code` column matching the codes used by
#' [get_estat()], so
#' the two join cleanly. Boundaries are derived from e-Stat's authoritative
#' small-area (町丁・字) shapefiles and dissolved to the requested `level`.
#'
#' Requires the \pkg{sf} package. Downloaded files are cached (see
#' [estat_cache_dir()]).
#'
#' @param areas Character vector of area codes selecting which prefectures to
#'   download: 2-digit prefecture codes (e.g. `"31"`) or any codes whose first
#'   two digits are a prefecture (e.g. a 5-digit `"31201"` or the `area_code`
#'   column from [get_estat()]). `NULL` downloads all 47 prefectures (large).
#' @param level Geographic level to return: `"municipality"` (default; 5-digit
#'   `PREF+CITY`) or `"prefecture"` (dissolved whole prefectures, `PREF+"000"`)
#'   or `"small_area"` (raw 町丁・字, 9-digit `KEY_CODE`).
#' @param year Census year of the boundaries (e.g. `2020`, `2015`). Match this to
#'   the census year of your data: municipality codes and boundaries change
#'   between censuses (mergers), so a mismatched year can mis-join.
#' @param datum Geodetic datum: `"2000"` (JGD2000, EPSG:4612, default) or
#'   `"2011"` (JGD2011, EPSG:6668).
#' @param cache If `TRUE` (default), cache downloaded boundary files under
#'   [estat_cache_dir()].
#' @param designated_cities How to handle the 20 ordinance-designated cities and
#'   Tokyo's special wards at `level = "municipality"`, since e-Stat's shapefiles
#'   carry only ward codes: `"both"` (default) returns ward polygons *and* a
#'   unioned parent-city polygon (e.g. both `01101`… and `01100` 札幌市), so data
#'   coded at either level joins; `"ward"` returns wards only; `"city"` returns
#'   the parent city only. Ignored for other levels.
#' @return An [sf][sf::st_sf] object with `area_code`, name columns, and geometry.
#' @export
#' @examples
#' \dontrun{
#' # Municipalities of Tottori (prefecture 31), 2020 census boundaries
#' bnd <- estat_boundaries("31", level = "municipality", year = 2020)
#' }
estat_boundaries <- function(areas = NULL,
                             level = c("municipality", "prefecture", "small_area"),
                             year = 2020, datum = c("2000", "2011"), cache = TRUE,
                             designated_cities = c("both", "ward", "city")) {
  check_sf_installed()
  level <- rlang::arg_match(level)
  datum <- rlang::arg_match(datum)
  designated_cities <- rlang::arg_match(designated_cities)
  validate_boundary_year_datum(year, datum)

  prefs <- resolve_prefectures(areas)
  if (is.null(areas) && length(prefs) > 40) {
    cli::cli_inform(c(
      "!" = "Downloading small-area boundaries for all {length(prefs)} prefectures (~250 MB).",
      "i" = "Pass {.arg areas} to fetch only the prefectures you need. Files are cached."
    ))
  }
  parts <- lapply(prefs, function(p) {
    sa <- read_boundary_small_area(p, year = year, datum = datum, cache = cache)
    dissolve_boundary(sa, level = level, designated = designated_cities)
  })
  out <- do.call(rbind, parts)

  # If specific (non-prefecture) codes were requested, filter down to them.
  if (!is.null(areas)) {
    wanted <- areas[nchar(areas) > 2]
    if (length(wanted) > 0) out <- out[out$area_code %in% wanted, ]
  }
  out
}

# Which 2-digit prefecture files do we need to cover the requested areas?
resolve_prefectures <- function(areas) {
  if (is.null(areas)) return(sprintf("%02d", 1:47))
  prefs <- unique(substr(as.character(areas), 1, 2))
  bad <- prefs[!grepl("^(0[1-9]|[1-4][0-9])$", prefs)]
  if (length(bad) > 0) {
    cli::cli_abort("Not valid prefecture codes: {.val {bad}}.", class = "estat_error_invalid_arg")
  }
  prefs
}

# Read one prefecture's small-area shapefile as a validated sf, from cache when
# available. Encapsulates all the fiddly correctness bits: CP932 encoding, CRS
# assignment, and geometry repair.
read_boundary_small_area <- function(pref, year = 2020, datum = "2000", cache = TRUE) {
  zip_path <- boundary_zip_path(pref, year, datum, cache)

  exdir <- file.path(tempfile("estat_bnd_"))
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(exdir, recursive = TRUE), add = TRUE)
  utils::unzip(zip_path, exdir = exdir)

  shp <- list.files(exdir, pattern = "\\.shp$", full.names = TRUE)[1]
  if (is.na(shp)) {
    cli::cli_abort(
      "No shapefile found in the e-Stat boundary download for prefecture {pref}.",
      class = "estat_error_boundary"
    )
  }

  x <- sf::st_read(shp, options = "ENCODING=CP932", quiet = TRUE)
  # The .prj has no EPSG code; assign the one implied by the chosen datum.
  sf::st_crs(x) <- boundary_epsg(datum)
  # e-Stat polygons occasionally carry invalid rings; repair before any union.
  x <- sf::st_make_valid(x)
  clean_boundary_rows(x)
}

# Drop rows that would corrupt a dissolve or a map:
#   * anomalous placeholder rows (short/NA KEY_CODE, NA CITY_NAME) that appear in
#     some vintages (e.g. Tokyo 2020's CITY="199" rows);
#   * water survey areas (HCODE == 8154, 水面調査区) that otherwise extend
#     municipal polygons out into harbours.
clean_boundary_rows <- function(x) {
  ok <- !is.na(x$KEY_CODE) & nchar(as.character(x$KEY_CODE)) >= 9 & !is.na(x$CITY_NAME)
  if ("HCODE" %in% names(x)) {
    ok <- ok & (is.na(x$HCODE) | as.character(x$HCODE) != "8154")
  }
  x[ok, ]
}

# Return a path to the (cached) boundary ZIP for one prefecture, downloading it
# if needed.
boundary_zip_path <- function(pref, year, datum, cache) {
  fname <- sprintf("bnd-%s-%s-%s.zip", year, datum, pref)
  cached <- file.path(cache_subdir("boundaries"), fname)
  if (cache && file.exists(cached) && file.size(cached) > 0) return(cached)

  url <- boundary_download_url(pref, year, datum)
  dest <- if (cache) cached else tempfile(fileext = ".zip")
  download_boundary(url, dest)
  dest
}

# Build the statmap-search download URL. dlserveyId = "A" + toukeiCode(00200521,
# the Population Census) + year; code = 2-digit prefecture; coordSys=1 gives
# geographic coordinates; downloadType=5 gives a shapefile; datum selects the
# JGD version.
boundary_download_url <- function(pref, year, datum) {
  survey_id <- paste0("A00200521", year)
  sprintf(
    "%s?dlserveyId=%s&code=%s&coordSys=1&format=shape&downloadType=5&datum=%s",
    estat_boundary_base_url(), survey_id, pref, datum
  )
}

# Download a boundary ZIP, verifying we actually got a zip (the service returns
# an HTML error page rather than an HTTP error for a bad request).
download_boundary <- function(url, dest) {
  req <- httr2::request(url)
  req <- httr2::req_user_agent(req, estat_user_agent())
  req <- httr2::req_retry(req, max_tries = 3, is_transient = estat_is_transient)
  resp <- httr2::req_perform(req, path = dest)

  ctype <- httr2::resp_content_type(resp)
  if (!is.na(ctype) && grepl("html", ctype, ignore.case = TRUE)) {
    cli::cli_abort(
      c(
        "e-Stat did not return a boundary file for this request.",
        "i" = "Check that the census {.arg year} and prefecture code are valid."
      ),
      class = "estat_error_boundary"
    )
  }
  invisible(dest)
}

# Dissolve small-area polygons up to the requested administrative level and
# attach a clean `area_code` plus name columns.
dissolve_boundary <- function(sa, level, designated = "both") {
  if (identical(level, "small_area")) {
    # Dissolve by KEY_CODE: a single small area can span several polygon rows.
    sa$area_code <- as.character(sa$KEY_CODE)
    name_cols <- intersect(c("PREF_NAME", "CITY_NAME", "S_NAME"), names(sa))
    return(stats::aggregate(
      sa[, name_cols], by = list(area_code = sa$area_code),
      FUN = function(z) z[1], do_union = TRUE
    ))
  }

  key <- if (identical(level, "prefecture")) {
    paste0(substr(sa$PREF, 1, 2), "000")
  } else {
    paste0(sa$PREF, sa$CITY) # municipality: PREF+CITY (5-digit)
  }
  sa$area_code <- key

  # Dissolve geometries by the derived code; carry the first name of each group.
  name_cols <- if (identical(level, "prefecture")) "PREF_NAME" else c("PREF_NAME", "CITY_NAME")
  agg <- stats::aggregate(
    sa[, name_cols],
    by = list(area_code = sa$area_code),
    FUN = function(z) z[1],
    do_union = TRUE
  )

  # For designated cities, e-Stat carries only ward codes; add (or substitute)
  # the unioned parent-city polygon so parent-level data can join.
  if (identical(level, "municipality") && !identical(designated, "ward")) {
    agg <- rollup_designated_cities(agg, mode = designated)
  }
  agg
}

# Union each designated city's ward polygons into a single parent-city polygon
# (coded e.g. 01100 札幌市). mode = "both" keeps wards and adds the parent;
# mode = "city" replaces the wards with the parent only. See .estatr_designated.
rollup_designated_cities <- function(muni, mode = "both") {
  codes <- suppressWarnings(as.integer(muni$area_code))
  keep <- rep(TRUE, nrow(muni))
  parents <- list()

  for (i in seq_len(nrow(.estatr_designated))) {
    d <- .estatr_designated[i, ]
    idx <- which(!is.na(codes) & codes >= d$ward_min & codes <= d$ward_max)
    if (length(idx) == 0) next

    # Build the parent row from a ward prototype so columns/CRS line up exactly.
    proto <- muni[idx[1], ]
    sf::st_geometry(proto) <- sf::st_union(sf::st_geometry(muni)[idx])
    proto$area_code <- d$parent_code
    if ("CITY_NAME" %in% names(proto)) proto$CITY_NAME <- d$parent_name
    parents[[length(parents) + 1L]] <- proto

    if (identical(mode, "city")) keep[idx] <- FALSE
  }

  if (length(parents) == 0) return(muni)
  do.call(rbind, c(list(muni[keep, ]), parents))
}

#' Attach boundary geometry to e-Stat data
#'
#' Joins e-Stat boundary polygons onto a tidy [get_estat()] result by
#' `area_code`, returning an \pkg{sf} object ready for choropleth mapping. Each data
#' row receives its area's geometry (so a long time series repeats geometry per
#' period, matching the tidycensus long-plus-geometry convention).
#'
#' @param data A tibble from [get_estat()] (decoded, with an `area_code` column).
#' @param level Geographic level, or `"auto"` (default) to infer: `"prefecture"`
#'   if every `area_code` ends in `"000"`, otherwise `"municipality"`.
#' @param year,datum,designated_cities Passed to [estat_boundaries()]. Match
#'   `year` to your data's census year. `designated_cities` defaults to `"both"`
#'   so data coded at either ward or parent-city level joins.
#' @return An [sf][sf::st_sf] object: the input columns plus a `geometry` column.
#' @export
#' @examples
#' \dontrun{
#' d <- get_population_census(cdCat01 = "0")
#' sf_d <- estat_join_geometry(d, level = "prefecture", year = 2020)
#' }
estat_join_geometry <- function(data, level = c("auto", "municipality", "prefecture", "small_area"),
                                year = 2020, datum = c("2000", "2011"),
                                designated_cities = c("both", "ward", "city")) {
  check_sf_installed()
  level <- rlang::arg_match(level)
  datum <- rlang::arg_match(datum)
  designated_cities <- rlang::arg_match(designated_cities)

  if (!"area_code" %in% names(data)) {
    cli::cli_abort(
      c(
        "{.arg data} has no {.field area_code} column to join geometry on.",
        "i" = "Use {.fn get_estat} with {.code decode_labels = TRUE} (the default)."
      ),
      class = "estat_error_no_area_code"
    )
  }

  codes <- unique(stats::na.omit(as.character(data$area_code)))
  if (identical(level, "auto")) {
    level <- if (length(codes) > 0 && all(grepl("000$", codes))) "prefecture" else "municipality"
  }

  bnd <- estat_boundaries(
    areas = codes, level = level, year = year, datum = datum,
    designated_cities = designated_cities
  )

  # Warn loudly about codes that got no geometry rather than silently returning
  # empty polygons -- the usual cause is a boundary year/level that doesn't match
  # the data (e.g. designated-city ward vs parent-city codes, or a merger year).
  unmatched <- setdiff(codes, bnd$area_code)
  if (length(unmatched) > 0) {
    cli::cli_warn(c(
      "{length(unmatched)} area code{?s} had no {level} geometry for year {year}.",
      "i" = "First few: {.val {utils::head(unmatched, 5)}}. Check that {.arg year}/{.arg level} match your data (municipality codes change between censuses; designated-city wards use ward codes)."
    ))
  }

  geom <- bnd[, "area_code"]
  out <- merge(geom, data, by = "area_code", all.y = TRUE)
  sf::st_as_sf(out)
}

# sf is a Suggests-only dependency; fail with an actionable message if the user
# calls into the geometry layer without it.
check_sf_installed <- function() {
  if (!requireNamespace("sf", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "The {.pkg sf} package is required for boundary geometry.",
        "i" = 'Install it with {.code install.packages("sf")}.'
      ),
      class = "estat_error_no_sf"
    )
  }
}

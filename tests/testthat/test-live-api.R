# Opt-in smoke tests against the real e-Stat API.
#
# Why these exist: every other test in this suite is mocked, which is the right
# default (fast, offline, deterministic). But a fully mocked suite cannot catch a
# break in the contract between this package and the live service -- and one did
# ship: estat_join_geometry() aborted on e-Stat's national total row while the
# suite stayed green. These tests exercise each exported entry point end to end.
#
# They are OFF unless you ask for them, because they hit a government server and
# cost real time:
#
#   Sys.setenv(ESTATR_TEST_LIVE = "true")
#   devtools::test(filter = "live-api")
#
# They also need a real appId in ESTAT_API_KEY (setup.R stashes it as
# `estatr_real_key` before the dummy key masks it).
#
# Assertions check SHAPE, not values: e-Stat revises figures and adds periods, so
# asserting on a specific number would make this suite fail for reasons that have
# nothing to do with the package.

# Skip unless live testing is explicitly enabled and a real key is available.
# Also restores the real appId for the duration of the calling test.
skip_unless_live <- function(env = parent.frame()) {
  skip_on_cran()
  if (!identical(tolower(Sys.getenv("ESTATR_TEST_LIVE")), "true")) {
    skip("Live API tests are opt-in: set ESTATR_TEST_LIVE=true")
  }
  if (!nzchar(estatr_real_key)) {
    skip("No real ESTAT_API_KEY available for live tests")
  }
  withr::local_envvar(ESTAT_API_KEY = estatr_real_key, .local_envir = env)
}

# A small, stable table used across several tests: Labour Force Survey,
# population aged 15+ by activity. National-only, so it stays cheap to fetch.
live_lfs_id <- "0003217721"
# 2020 Population Census, population by sex. Has a full geography hierarchy
# (national / prefecture / city / ward), so it exercises the geometry paths.
live_census_id <- "0003433219"

# -- discovery ---------------------------------------------------------------

test_that("live: search_estat returns the friendly column set", {
  skip_unless_live()
  r <- search_estat("Labour Force Survey", limit = 3)

  expect_s3_class(r, "tbl_df")
  expect_gt(nrow(r), 0)
  # The renamed, front-of-table columns search_estat() promises.
  expect_true(all(c("id", "stat_name", "statistics_name", "title", "cycle") %in% names(r)))
  expect_type(r$id, "character")
  expect_match(r$id[[1]], "^[0-9]+$")
})

test_that("live: estat_stats_list returns raw e-Stat column names", {
  skip_unless_live()
  r <- estat_stats_list(searchWord = "Population Census", limit = 3)

  expect_s3_class(r, "tbl_df")
  expect_gt(nrow(r), 0)
  # Low-level wrapper: e-Stat's own names, not the snake_case ones.
  expect_true(all(c("id", "STATISTICS_NAME") %in% names(r)))
})

test_that("live: estat_data_catalog returns catalog entries", {
  skip_unless_live()
  r <- estat_data_catalog(searchWord = "Population Census", limit = 3)

  expect_s3_class(r, "tbl_df")
  expect_gt(nrow(r), 0)
  expect_true("id" %in% names(r))
})

# -- metadata ----------------------------------------------------------------

test_that("live: estat_meta_info returns one decoded table per axis", {
  skip_unless_live()
  m <- estat_meta_info(live_census_id)

  expect_type(m, "list")
  expect_true(all(c("cat01", "area", "time") %in% names(m)))
  for (axis in names(m)) {
    expect_s3_class(m[[axis]], "tbl_df")
    expect_true(all(c("code", "name") %in% names(m[[axis]])))
    expect_gt(nrow(m[[axis]]), 0)
  }
  # The area axis carries the hierarchy the geometry layer depends on.
  expect_true(all(c("level", "parent") %in% names(m$area)))
})

# -- data --------------------------------------------------------------------

test_that("live: get_estat returns paired label/code columns and a numeric value", {
  skip_unless_live()
  d <- get_estat(live_lfs_id, limit = 20)

  expect_s3_class(d, "tbl_df")
  expect_equal(nrow(d), 20)
  # Every axis decodes to a label + code pair.
  expect_true(all(c("area", "area_code", "time", "time_code") %in% names(d)))
  expect_true(all(c("unit", "value", "annotation") %in% names(d)))
  expect_type(d$value, "double")
  expect_type(d$area_code, "character")
  # Labels actually decoded rather than staying as codes.
  expect_false(any(d$area == d$area_code))
  # The annotation legend travels with the data.
  expect_s3_class(attr(d, "notes"), "tbl_df")
})

test_that("live: limit caps the number of rows returned", {
  skip_unless_live()
  expect_equal(nrow(get_estat(live_lfs_id, limit = 1)), 1L)
  expect_equal(nrow(get_estat(live_lfs_id, limit = 7)), 7L)
})

test_that("live: pagination assembles a table larger than one page", {
  skip_unless_live()
  # This table is well over a single 100k-record page's worth of rows once
  # unfiltered; the point is that the paginator returns a coherent whole.
  d <- get_estat(live_lfs_id)

  expect_gt(nrow(d), 1000)
  expect_false(any(duplicated(d)))
  expect_type(d$value, "double")
})

test_that("live: decode_labels = FALSE returns coded columns only", {
  skip_unless_live()
  d <- get_estat(live_lfs_id, limit = 5, decode_labels = FALSE)

  expect_s3_class(d, "tbl_df")
  # Raw axis names, no _code partners, because nothing was decoded.
  expect_true("area" %in% names(d))
  expect_false("area_code" %in% names(d))
  expect_match(d$area[[1]], "^[0-9]+$")
})

test_that("live: as_data_table returns a data.table", {
  skip_unless_live()
  d <- get_estat(live_lfs_id, limit = 5, as_data_table = TRUE)
  expect_s3_class(d, "data.table")
})

test_that("live: filters narrow the result server-side", {
  skip_unless_live()
  d <- get_estat(live_census_id, cdCat01 = "0", lvArea = "2")

  # lvArea = "2" is prefecture level: exactly the 47 prefectures, no national
  # total and no municipalities.
  expect_equal(nrow(d), 47L)
  expect_true(all(grepl("000$", d$area_code)))
  expect_false("00000" %in% d$area_code)
})

test_that("live: lang = 'J' returns Japanese labels", {
  skip_unless_live()
  d <- get_estat(live_lfs_id, limit = 2, lang = "J")
  # Any CJK character confirms we got the Japanese release, not English.
  expect_match(paste(d$area, collapse = ""), "[　-鿿]")
})

test_that("live: a bad statsDataId surfaces the e-Stat error message", {
  skip_unless_live()
  expect_error(get_estat("9999999999", limit = 1), "does not exist")
})

# -- curated shortcuts -------------------------------------------------------

test_that("live: curated shortcut wrappers each fetch their table", {
  skip_unless_live()
  # One call per wrapper, kept small; this is a contract check that the curated
  # statsDataIds still resolve to live tables.
  for (fn in list(get_labour_force_survey, get_population_census,
                  get_economic_census)) {
    d <- suppressWarnings(fn(limit = 3))
    expect_s3_class(d, "tbl_df")
    expect_equal(nrow(d), 3L)
    expect_true("value" %in% names(d))
  }
})

test_that("live: every curated statsDataId is still valid", {
  skip_unless_live()
  ids <- stats::na.omit(estat_curated_tables()$statsDataId)
  for (id in ids) {
    d <- suppressWarnings(get_estat(id, limit = 1))
    expect_equal(nrow(d), 1L, info = id)
  }
})

# -- reshaping ---------------------------------------------------------------

test_that("live: pivot_estat_wide widens a real result", {
  skip_unless_live()
  d <- get_estat(live_census_id, lvArea = "2")
  w <- pivot_estat_wide(d, names_from = "cat01", values_from = "value")

  expect_s3_class(w, "tbl_df")
  expect_equal(nrow(w), 47L)
  # The three sex categories become columns.
  expect_true(all(c("Total", "Male", "Female") %in% names(w)))
  expect_type(w$Total, "double")
})

# -- geometry ----------------------------------------------------------------

test_that("live: estat_boundaries downloads and dissolves real polygons", {
  skip_unless_live()
  skip_if_not_installed("sf")
  # Tottori (31) is the smallest prefecture file, so this stays quick.
  b <- estat_boundaries("31", level = "municipality", year = 2020)

  expect_s3_class(b, "sf")
  expect_gt(nrow(b), 0)
  expect_true("area_code" %in% names(b))
  expect_true(all(grepl("^31[0-9]{3}$", b$area_code)))
  expect_equal(sf::st_crs(b)$epsg, 4612L)
  expect_false(any(sf::st_is_empty(b)))
  # Geometry repair ran: no invalid rings survive the read.
  expect_true(all(sf::st_is_valid(b)))
})

test_that("live: estat_join_geometry attaches polygons to real data", {
  skip_unless_live()
  skip_if_not_installed("sf")
  d <- get_estat(live_census_id, cdCat01 = "0", lvArea = "2")
  j <- estat_join_geometry(d, level = "prefecture", year = 2020)

  expect_s3_class(j, "sf")
  expect_equal(nrow(j), nrow(d))
  expect_false(any(sf::st_is_empty(j)))
  expect_equal(sf::st_crs(j)$epsg, 4612L)
})

test_that("live: the national total row does not break a geometry join", {
  skip_unless_live()
  skip_if_not_installed("sf")
  # Regression test for the bug this file exists to catch: e-Stat returns the
  # national total ("00000") in nearly every table, and it used to abort the
  # whole join with `Not valid prefecture codes: "00"`.
  d <- get_estat(live_census_id, cdCat01 = "0")
  d <- d[grepl("000$", d$area_code), ] # prefectures + the national total
  expect_true("00000" %in% d$area_code)

  j <- suppressMessages(estat_join_geometry(d, level = "prefecture", year = 2020))

  expect_s3_class(j, "sf")
  # The national row is kept, not dropped, so row counts still line up.
  expect_equal(nrow(j), nrow(d))
  expect_true(sf::st_is_empty(j[j$area_code == "00000", ]))
  # ...and every real prefecture still got its polygon.
  expect_false(any(sf::st_is_empty(j[j$area_code != "00000", ])))
})

test_that("live: get_estat(geometry = TRUE) returns a mappable sf", {
  skip_unless_live()
  skip_if_not_installed("sf")
  d <- get_estat(live_census_id, cdCat01 = "0", lvArea = "2", geometry = TRUE,
                 geometry_level = "prefecture", geometry_year = 2020)

  expect_s3_class(d, "sf")
  expect_equal(nrow(d), 47L)
  expect_true(all(c("value", "area_code") %in% names(d)))
  expect_false(any(sf::st_is_empty(d)))
})

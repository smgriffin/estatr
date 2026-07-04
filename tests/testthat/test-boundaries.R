# Pure helpers first -- these need no sf and run everywhere.

test_that("boundary_download_url builds the statmap-search URL", {
  url <- boundary_download_url("31", 2020, "2000")
  expect_match(url, "statmap-search/data")
  expect_match(url, "dlserveyId=A002005212020")
  expect_match(url, "code=31")
  expect_match(url, "coordSys=1")
  expect_match(url, "format=shape")
  expect_match(url, "datum=2000")
})

test_that("boundary_epsg maps datum to the right EPSG code", {
  expect_equal(boundary_epsg("2000"), 4612L) # JGD2000
  expect_equal(boundary_epsg("2011"), 6668L) # JGD2011
})

test_that("resolve_prefectures extracts 2-digit codes and rejects bad ones", {
  expect_equal(resolve_prefectures("31"), "31")
  expect_equal(resolve_prefectures(c("31201", "31202", "13000")), c("31", "13"))
  expect_length(resolve_prefectures(NULL), 47L)
  expect_error(resolve_prefectures("99"), class = "estat_error_invalid_arg")
})

test_that("validate_boundary_year_datum enforces available years/datums", {
  expect_silent(validate_boundary_year_datum(2020, "2000"))
  expect_silent(validate_boundary_year_datum(2020, "2011"))
  expect_error(validate_boundary_year_datum(1995, "2000"), class = "estat_error_invalid_arg")
  # JGD2011 only exists for 2015/2020
  expect_error(validate_boundary_year_datum(2010, "2011"), class = "estat_error_invalid_arg")
  expect_silent(validate_boundary_year_datum(2015, "2011"))
})

test_that("estat_join_geometry needs an area_code column", {
  skip_if_not_installed("sf")
  expect_error(
    estat_join_geometry(tibble::tibble(x = 1)),
    class = "estat_error_no_area_code"
  )
})

# sf-dependent behaviour -- skipped when sf is unavailable (CI/CRAN without it).

# Build a tiny in-memory small-area sf: prefecture "99", two municipalities
# (99201 with two small-areas, 99202 with one), as unit squares.
make_fake_small_area <- function() {
  sq <- function(x0, y0) {
    sf::st_polygon(list(rbind(
      c(x0, y0), c(x0 + 1, y0), c(x0 + 1, y0 + 1), c(x0, y0 + 1), c(x0, y0)
    )))
  }
  sf::st_sf(
    KEY_CODE = c("992010010", "992010020", "992020010"),
    PREF = c("99", "99", "99"),
    CITY = c("201", "201", "202"),
    PREF_NAME = c("架空県", "架空県", "架空県"),
    CITY_NAME = c("東市", "東市", "西市"),
    S_NAME = c("一丁目", "二丁目", "本町"),
    geometry = sf::st_sfc(sq(0, 0), sq(1, 0), sq(2, 0), crs = 4612)
  )
}

test_that("dissolve_boundary rolls small-areas up to municipality codes", {
  skip_if_not_installed("sf")
  muni <- dissolve_boundary(make_fake_small_area(), "municipality")
  expect_s3_class(muni, "sf")
  expect_setequal(muni$area_code, c("99201", "99202"))
  expect_equal(nrow(muni), 2L) # two small-areas of 99201 dissolved into one
})

test_that("dissolve_boundary rolls up to a single prefecture polygon", {
  skip_if_not_installed("sf")
  pref <- dissolve_boundary(make_fake_small_area(), "prefecture")
  expect_equal(nrow(pref), 1L)
  expect_equal(pref$area_code, "99000")
})

test_that("small_area level keeps the 9-digit KEY_CODE", {
  skip_if_not_installed("sf")
  sa <- dissolve_boundary(make_fake_small_area(), "small_area")
  expect_setequal(sa$area_code, c("992010010", "992010020", "992020010"))
})

test_that("clean_boundary_rows drops water areas and anomalous rows", {
  skip_if_not_installed("sf")
  pt <- function(i) sf::st_point(c(i, i))
  x <- sf::st_sf(
    KEY_CODE = c("992010010", "992010020", "13", "992020010"),
    CITY_NAME = c("東市", "東市", NA, "西市"),
    HCODE = c("8101", "8154", "8101", "8101"), # second is a water area
    geometry = sf::st_sfc(pt(1), pt(2), pt(3), pt(4), crs = 4612)
  )
  cleaned <- clean_boundary_rows(x)
  # Keeps only the two valid, non-water rows.
  expect_equal(nrow(cleaned), 2L)
  expect_setequal(cleaned$KEY_CODE, c("992010010", "992020010"))
})

test_that("estat_join_geometry warns about area codes with no geometry", {
  skip_if_not_installed("sf")
  fake_muni <- dissolve_boundary(make_fake_small_area(), "municipality") # 99201, 99202
  testthat::local_mocked_bindings(
    estat_boundaries = function(areas, level, year, datum) fake_muni
  )
  d <- tibble::tibble(area_code = c("99201", "99999"), value = c(1, 2))
  expect_warning(estat_join_geometry(d, level = "municipality"), "no municipality geometry")
})

test_that("estat_join_geometry attaches geometry to data rows by area_code", {
  skip_if_not_installed("sf")
  fake_muni <- dissolve_boundary(make_fake_small_area(), "municipality")
  testthat::local_mocked_bindings(
    estat_boundaries = function(areas, level, year, datum) fake_muni
  )
  d <- tibble::tibble(
    area_code = c("99201", "99202", "99201"),
    time = c("2020", "2020", "2015"),
    value = c(10, 20, 9)
  )
  out <- estat_join_geometry(d, level = "municipality")
  expect_s3_class(out, "sf")
  expect_equal(nrow(out), 3L) # geometry repeated per period
  expect_setequal(out$value, c(10, 20, 9))
})

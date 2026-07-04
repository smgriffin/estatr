# Performance-regression guard rails.
#
# These exist to catch a *silent 10x regression* in the hot paths (bulk
# JSON->table conversion and the code->label join), not to benchmark precisely.
# The thresholds are deliberately generous so they never flake on a slow CI
# runner but still trip if someone reintroduces a row-wise loop where a bulk
# data.table op belongs. Skipped on CRAN (no long-running tests there).

skip_on_cran()
skip_if_not_installed("bench")

# Build N synthetic getStatsData VALUE records as nested lists (the shape
# records_to_dt / flatten_record actually receive).
make_value_records <- function(n) {
  areas <- sprintf("%05d", seq_len(50) * 1000)
  times <- sprintf("2020%06d", seq_len(40))
  cats <- sprintf("%03d", seq_len(25))
  lapply(seq_len(n), function(i) {
    list(
      "@tab" = "01",
      "@cat01" = cats[[(i %% 25) + 1]],
      "@area" = areas[[(i %% 50) + 1]],
      "@time" = times[[(i %% 40) + 1]],
      "@unit" = "人",
      "$" = as.character(i)
    )
  })
}

test_that("bulk VALUE parsing stays fast (column-wise, no row-wise regression)", {
  recs <- make_value_records(30000L)
  # flat_records_to_dt is the hot path used by values_from_bodies. A row-wise
  # or per-record-as.data.table regression would blow past this generous bound.
  tm <- bench::mark(flat_records_to_dt(recs), iterations = 2, check = FALSE, filter_gc = FALSE)
  expect_lt(as.numeric(tm$median), 3)
})

test_that("code->label decoding stays fast (data.table join, not per-row)", {
  n <- 30000L
  dt <- data.table::data.table(
    area = sprintf("%05d", (seq_len(n) %% 50 + 1) * 1000),
    time = sprintf("2020%06d", seq_len(n) %% 40 + 1),
    cat01 = sprintf("%03d", seq_len(n) %% 25 + 1),
    value = as.numeric(seq_len(n))
  )
  tables <- list(
    area = tibble::tibble(code = unique(dt$area), name = paste0("area-", unique(dt$area)),
                          level = NA_character_, unit = NA_character_, parent = NA_character_),
    time = tibble::tibble(code = unique(dt$time), name = paste0("t-", unique(dt$time)),
                          level = NA_character_, unit = NA_character_, parent = NA_character_),
    cat01 = tibble::tibble(code = unique(dt$cat01), name = paste0("c-", unique(dt$cat01)),
                           level = NA_character_, unit = NA_character_, parent = NA_character_)
  )
  tm <- bench::mark(decode_axes(data.table::copy(dt), tables), iterations = 2,
                    check = FALSE, filter_gc = FALSE)
  expect_lt(as.numeric(tm$median), 5)
})

# Contributing to estatr

Thanks for taking the time to contribute!

## Ground rules

- **Never commit an appId.** Tests run entirely offline against mocked
  responses; you do not need a real e-Stat key to work on the package or
  to get CI passing. If you record fixtures against the live API, the
  redactor in `tests/testthat/setup.R` scrubs the `appId` — verify it
  did before committing.
- Keep package internals dependency-lean: `data.table` for hot paths,
  `httr2` for HTTP, `rlang`/`cli` for conditions and messaging.
  `dplyr`/`purrr` are for vignette examples only, never package code.
  Use the base pipe (`|>`) and base regex over `magrittr`/`stringr`.
- Every exported function validates its arguments before hitting the
  network and surfaces e-Stat errors as classed conditions, not raw HTTP
  errors.

## Development workflow

``` r

# Load the package for interactive work
pkgload::load_all()

# Run tests (offline, no key required)
devtools::test()

# Regenerate documentation after editing roxygen comments
devtools::document()

# Full check before opening a PR
devtools::check()
```

## Pull requests

1.  Fork and create a feature branch.
2.  Add tests for any behaviour change; keep them offline.
3.  Run `devtools::check()` and make sure it is clean.
4.  Update `NEWS.md` with a user-facing summary.

## Code of Conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://smgriffin.github.io/estatr/CODE_OF_CONDUCT.md). By
participating you agree to abide by its terms.

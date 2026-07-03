## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.

## Test environments

* local macOS, R 4.4.3
* GitHub Actions: Windows / macOS / Ubuntu, R release, oldrel-1, and devel

## Notes for CRAN

* The package is a client for the e-Stat API (the Japanese government statistics
  portal). All examples that call the API are wrapped in `\dontrun{}` because
  they require a free personal application ID (`appId`) and a network
  connection. Vignette chunks that hit the API are set to `eval = FALSE` for the
  same reason.
* The test suite runs fully offline against mocked responses; no API key or
  network access is required to check the package. A separate, manually
  triggered CI job exercises the live API on a schedule.
* No API key or other secret is stored in the package. The `appId` is read from
  an environment variable at call time and is redacted from any surfaced error
  message, request URL, or recorded fixture.

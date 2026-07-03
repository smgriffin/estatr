# estatr 0.0.0.9000

* First development release, establishing the HTTP/auth foundation (roadmap milestones M0–M1).
* `estat_api_key()` and `estat_api_key_exists()` manage your e-Stat `appId`, modelled on `tidycensus::census_api_key()`. The key lives in an environment variable and is never stored in package state or printed.
* Internal `httr2`-based request layer: JSON endpoints by default, UTF-8 query encoding for Japanese search terms, gzip, transient-only retry, and client-side throttling.
* Central response handler treats e-Stat's `RESULT.STATUS` (not just HTTP status) as the source of truth, maps error codes to classed conditions (`estat_error_invalid_param`, `estat_error_no_data`, and so on), and scrubs the `appId` from every surfaced message, URL, and fixture.
* `estat_stats_list()` wraps `getStatsList`, returning a tibble with e-Stat's nested code/label objects flattened via `data.table`.

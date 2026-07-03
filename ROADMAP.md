# Roadmap: R package for Japanese government statistics (e-Stat API)

A tidycensus-style R package wrapping the main **e-Stat API** (`api.e-stat.go.jp`), the government-wide statistics catalog (Population Census, Labour Force Survey, Economic Census, etc.). This is the full-catalog API, not the narrower no-auth Statistics Dashboard API — closer in scope to what the Census Bureau API is to tidycensus.

Package name: **`estatr`** (confirmed available on CRAN and GitHub).

## What Claude Code needs to know about the API first

- Base URL: `https://api.e-stat.go.jp/rest/<version>/app/...` (current version 3.0). Formats: XML (default), JSON (`/app/json/...`), JSONP.
- Auth: free `appId`, obtained by signing up and pressing "Issue" on the e-Stat mypage. **Max 3 appIds per account.** No documented rate limit currently, but must display required credit text in any published app (see e-Stat Terms of Use).
- Four core endpoints to wrap:
  - `getStatsList` — search/list statistical tables (search by keyword, stat code, government org, update date, etc.) → returns table IDs (`@id`, ~10 digits).
  - `getMetaInfo` — given a `statsDataId`, returns the classification metadata (categories, area codes, time codes, tab codes) needed to decode a table before pulling data.
  - `getStatsData` — given a `statsDataId` + filter codes (`cdCat01`, `cdArea`, `cdTime`, etc.), returns the actual values.
  - `getDataCatalog` — finds raw files (Excel/CSV/PDF) and datasets; returns only URLs, not machine-readable data itself. Lower priority.
- **Pagination**: `getStatsData` caps at 100,000 records per call. Response includes `NEXT_KEY` when more exist; keep requesting with `startPosition = NEXT_KEY` until exhausted. This must be handled transparently inside the package, not left to the user. Note that `NEXT_KEY`/`startPosition` is an **absolute integer row offset** (1-based), not an opaque cursor token — this is what makes concurrent page fan-out possible (see Performance), but it must be confirmed empirically before the parallel architecture is built on top of it (see M2).
- Response envelope is consistent across endpoints: a `RESULT` block (status/error), a `PARAMETER` echo-back, and an endpoint-specific data block. Non-zero `STATUS` = error; surface `ERROR_MSG` to the user via a condition, don't just return an empty tibble.
- Existing prior art: CRAN package `estatapi` is a thin 1:1 wrapper around these four endpoints returning tibbles, with no metadata decoding into labels, no search ergonomics beyond raw keyword match, no geography/boundary support, and no caching. That's the gap this package fills — think of `estatapi` as roughly what `httr` + raw JSON parsing is to `tidycensus`.

## Design principles

- **Fast internals, familiar boundary.** Robustness and speed are explicit priorities for this package, so it deliberately does not copy tidycensus's all-tidyverse internals. `data.table` is the internal engine for the actual hot paths — JSON-to-table conversion, code→label joins, assembling paginated results — since that's where real cost lives on large e-Stat tables (area mesh, long time series). Every exported function converts to a plain tibble (`tibble::as_tibble()`, a near-free class wrap, not a `dplyr` operation) only at the return boundary, so output still pipes into `dplyr`/`ggplot2` the way tidycensus users expect. `dplyr` and `purrr` are Suggests (used in vignette examples only), never package internals. Use the base pipe (`|>`, requires R ≥ 4.1) instead of `magrittr`; use base R regex (or `stringi` directly if genuinely needed) instead of `stringr`. `httr2`, `rlang`, and `cli` stay as Imports — they aren't the source of tidyverse slowness and buy real robustness (structured HTTP handling, classed conditions, good messaging) cheaply.
- snake_case functions mirroring tidycensus naming (`get_estat()`, `search_estat()`), not literal endpoint names, as the primary UX — keep low-level `estat_*` functions available for power users, same two-tier pattern tidycensus uses internally.
- API key management modeled on `census_api_key()`: `estat_api_key(key, install = TRUE)` writes to `.Renviron`, package reads `Sys.getenv("ESTAT_API_KEY")` at call time, never stored in package state.
- Long/tidy output by default (one row per observation, category/area/time as label columns), with an explicit pivot helper for wide output — same tradeoff tidycensus makes with `output = "wide"`.
- Decode codes to human labels using `getMetaInfo`, joined in automatically, with an option to keep raw codes for joins.
- Fail loudly and specifically: e-Stat's own error codes/messages should surface as informative R conditions, not generic HTTP errors.
- No live network calls required to run the test suite (see Testing below) — contributors and CI shouldn't need a personal appId to get tests passing.

## Robustness & performance guidelines

These apply across milestones (referenced inline below where they change scope), not a separate phase — bolting them on after the fact is expensive.

**Robustness / correctness**
- Validate every exported function's arguments before hitting the network (`rlang::arg_match()`/assertion-style checks on `statsDataId` format, code vectors, date ranges); fail with a specific message, not a raw HTTP error two layers down.
- Treat e-Stat's `RESULT.STATUS` as the real source of truth for errors, not HTTP status alone — a request can come back HTTP 200 with a non-zero e-Stat status. Map documented status codes to distinct R condition classes (e.g. `estat_error_invalid_param`, `estat_error_no_data`) so callers can `tryCatch()` on specifics instead of parsing error strings.
- Only retry transient failures (timeouts, 5xx, connection reset). Never retry 4xx / e-Stat-level parameter errors — retrying a malformed request just wastes time and hides the real bug from the user.
- Defensive response parsing: check expected fields exist before indexing into them. The API's shape has changed across versions before (2.1 → 3.0); a missing key should raise "unexpected response shape from e-Stat, please file an issue," not a cryptic `NULL` subscript error.
- Resumable pagination: for a `getStatsData` pull that dies partway through a multi-million-row table (network blip, session crash), persist enough state to resume instead of restarting from zero. Because pages are fetched by absolute offset in parallel (see Performance), the checkpoint is a **manifest of completed offset ranges**, not a single "last `NEXT_KEY`" — resume means re-requesting only the gaps. (The single-cursor "last key" model only works for the sequential fallback path; don't design the checkpoint around it.)
- Encoding correctness: e-Stat mixes Japanese and English text and some legacy tables carry non-UTF-8 artifacts. Every response must be explicitly parsed as UTF-8, and test fixtures must include non-ASCII table/category names, not just English demo tables.
- No official rate limit today per the e-Stat FAQ, but that's not a license to hammer a government server — build in client-side request throttling and `Retry-After` handling from M1, not after getting informally blocked in production.
- Cross-platform CI matrix (Windows/macOS/Linux × R release/oldrel/devel) — encoding and file-path bugs on Windows are the most common way a package that works for the author breaks for everyone else.
- Once on CRAN, treat exported function signatures as a compatibility contract: deprecate via `lifecycle::deprecate_warn()` before removing/renaming, keep `NEWS.md` current with every user-facing change.

**Performance**
- Prefer JSON over XML on the wire — smaller payload, and `jsonlite` parses faster in R than walking an XML DOM. Default all internal requests to the JSON endpoints. (The CSV endpoints — `getSimpleStatsData` — return an even more compact payload for the bulk path and could be evaluated as a faster wire format for very large pulls; treat as an optional optimization, not the default, since they carry less metadata.)
- Confirm gzip compression is actually active on requests (`httr2`/curl support it, but verify it isn't silently disabled) — matters a lot on tables with hundreds of thousands of rows.
- The first page of a `getStatsData` response includes the total record count. Use it to compute the absolute row offsets of the *remaining* pages and fan them out as concurrent requests (`httr2::req_perform_parallel()`) instead of the naive sequential "follow NEXT_KEY one page at a time" loop. This is the single biggest speed win available for large tables and isn't something `estatapi` does today — worth calling out as a differentiator. **This is "parallel but polite": cap concurrency explicitly (`max_active` ≈ 4–6) and keep the M1 client-side throttle active underneath it, rather than firing all pages at once.** Unbounded fan-out at a government server is exactly what the "no rate limit today isn't a license to hammer" guideline below warns against; the throttle and the parallelism are designed to coexist, with the concurrency cap as the reconciliation between them.
- Vectorize response-to-table conversion using `jsonlite` simplify + `data.table` (`rbindlist()` for assembling paginated chunks, `:=` for in-place column ops); avoid row-wise loops (`purrr::map()`, `apply()`, or otherwise) over thousands of records for what should be one bulk parse. Convert to tibble only once, at the very end, for the object the user actually receives.
- Code→label decoding should be a `data.table` binary join (`on =`/merge by key) against the metadata lookup, not a per-row lookup and not a `dplyr::left_join` — this is exactly the operation that gets slow at scale under `dplyr`.
- Benchmark the hot paths (large-table parsing, label joins, pagination fan-out) with the `bench` package, and keep a small perf-regression check in CI so a future change doesn't silently make a 500k-row pull 10x slower. This only matters for the big tables (area mesh, long time series) — a typical 47-prefecture pull is a few dozen rows either way, so don't let chasing this turn into rewriting code paths that were never slow.
- Two power-user fast paths, consistent with each other: `decode_labels = FALSE` skips the metadata join entirely; a second argument (e.g. `as_data_table = TRUE`) skips the final tibble conversion and returns the internal `data.table` directly, for bulk-analysis users who don't want to pay even that small boundary cost.

## Phased milestones

### M0 — Project setup
- Confirm package name is free on CRAN and GitHub; register repo.
- `usethis`-based scaffold: DESCRIPTION, license (MIT + LICENSE file), `.Rbuildignore`, GitHub Actions (R-CMD-check, test-coverage), README skeleton, code of conduct/contributing docs.
- Dependency stack, chosen for speed and a lean tree, not tidyverse-by-default (per Design principles above):
  - **Imports**: `httr2` (HTTP), `data.table` (internal parsing/joins/reshaping — the actual performance engine), `tibble` (thin class wrap at the return boundary only), `jsonlite` (JSON parsing), `rlang` + `cli` (classed conditions, messaging), `curl`, `rappdirs` (cache location), `memoise` (in-session memoization of `getMetaInfo` lookups — see M3, where the metadata join happens; defer adding it until that use lands rather than importing it unused at M0), `lifecycle` (deprecation discipline once on CRAN).
  - **`data.table` `R CMD check` chore**: internal NSE (`:=`, `.`, bare column names) reliably trips "no visible binding for global variable" NOTEs that CRAN flags. Set `.datatable.aware = TRUE` in the package and declare the symbols via `utils::globalVariables()` from the first data.table code (M2), not as a scramble at submission time.
  - **Suggests only** (never in package internals): `dplyr`, `purrr` — for vignette examples showing users how to chain package output into their own tidyverse code; `bench` — perf regression tests; `sf`/`jpndistrict`/`jpmesh` — deferred to the geography milestone.
  - **Explicitly avoided**: `magrittr` (use base `|>`, require R ≥ 4.1), `stringr` (use base regex or `stringi` directly if needed).
- Set up the cross-platform GitHub Actions CI matrix (Windows/macOS/Linux × R release/oldrel/devel) now, not later — catching a Windows encoding bug in M1 is cheap, catching it after CRAN release is not.

### M1 — HTTP client & auth
- Internal request builder: constructs URLs/query params, URL-encodes UTF-8 values (needed for Japanese-language search terms and `#`-prefixed codes), attaches `appId`, sets JSON format by default.
- `estat_api_key()` / `estat_api_key_exists()` following the census_api_key pattern.
- Central response handler: parses the `RESULT` block first, raises a classed condition (`estat_api_error`) with the e-Stat status code and message on failure, otherwise passes the data block onward. **Scrub the `appId` from everything the handler surfaces** — it travels in the query string, so it can leak via the `PARAMETER` echo-back, the request URL in a condition object, or `httr2` verbose/`last_request()` output. Redact it to `appId=<hidden>` before any value reaches a message, condition, or log (see Credential hygiene).
- Retry/backoff for transient network failures only (`httr2::req_retry`, capped attempts, exponential backoff) — never retry on e-Stat-level parameter errors, see Robustness guidelines above.
- Client-side request throttling (minimum spacing between calls) baked in here, not added later.

### M2 — Core endpoint wrappers (parity with `estatapi`, tibble output)
- `estat_stats_list()` → wraps `getStatsList`.
- `estat_meta_info()` → wraps `getMetaInfo`, returns a named list of tibbles (one per classification axis: `cat01`, `area`, `time`, `tab`, etc.), matching the shape analysts expect from having used `estatapi`.
- `estat_stats_data()` → wraps `getStatsData`, with **automatic, parallelized pagination** baked in: use the total record count from page one to fan out remaining pages concurrently (see Performance guidelines above) rather than the naive sequential `NEXT_KEY` loop — this is a real improvement over `estatapi`, which leaves pagination to the user.
  - **Gate the parallel architecture on two confirmations up front, before building on it:**
    1. **`startPosition` is a true absolute offset** — verify empirically against a live table that computing page offsets from `TOTAL_NUMBER` returns the same rows as following the `NEXT_KEY` chain. The whole fan-out premise collapses to sequential if it isn't; find that out on day one, not after M3 is built on top.
    2. **`httptest2` can record/replay `req_perform_parallel()`** — confirm the offline test harness intercepts parallel requests the same way it does `req_perform()`. If it can't, put the mock seam at the "fetch these N offsets" layer (mock the function that dispatches the batch, not each individual HTTP call) so the fan-out path stays testable in CI without a live appId. Keep a sequential fallback path regardless.
- `estat_data_catalog()` → wraps `getDataCatalog` (lower priority, can slip to M5 if time-constrained).
- Golden-path integration test script (run manually against a real appId, not in CI) to validate against live data.

### M3 — Tidy output & label decoding
- `get_estat()`: the tidycensus-equivalent high-level entry point. Takes a `statsDataId` (or a curated table name, see M4), fetches data + metadata in one call, does the join/reshape work in `data.table` internally, and returns a tibble at the boundary with `area`, `area_code`, `time`, `time_code`, category label columns, `unit`, `value` — see Design principles and Performance guidelines above for why the internal/external split exists, and the `decode_labels`/`as_data_table` escape hatches.
- `pivot_estat_wide()` helper for wide reshaping (categories/time as columns) — implemented with `data.table::dcast()` internally, mirrors tidycensus `output = "wide"` without forcing it as the default.
- Numeric coercion, annotation/footnote handling (e-Stat marks suppressed or annotated values distinctly). **Default to a separate `flag`/`annotation` column, not silent `NA`.** Coercing suppressed or footnoted values straight to `NA` is lossy and unrecoverable downstream — a flag column keeps `value` clean while preserving *why* a cell is missing or caveated, which is what analysts actually need. (Silent `NA` coercion can be an opt-in, not the default.)

### M4 — Discovery & curated convenience wrappers
- `search_estat()`: friendlier search over `getStatsList` (keyword, government org, category, update-date range) returning a tibble ranked/filtered for interactive use.
- Curated shortcut functions for the handful of tables most users will actually want first, shipped as internal lookup data (named `statsDataId`s), e.g. `get_population_census()`, `get_labour_force_survey()`, `get_economic_census()`, `get_family_income_survey()` — this is the single biggest tidycensus-style UX win, since hunting for the right `statsDataId` by hand is the main friction point today.
- Area code reference data: bundled lookup table of JIS prefecture (都道府県) and municipality (市区町村) codes with English/Japanese names, for joining and filtering without another API round-trip.

### M5 — Caching & robustness
- Cache `getMetaInfo` results and the curated table-ID lookup to a user cache dir (`rappdirs::user_cache_dir()`), since metadata rarely changes and re-fetching on every call is wasteful (same rationale as `tigris`'s shapefile cache).
- `estat_cache_clear()` / cache TTL option.
- Resumable pagination checkpointing for large pulls (see Robustness guidelines above) — persist the **manifest of completed offset ranges** under the cache dir so an interrupted multi-million-row pull resumes by re-requesting only the gaps, consistent with the parallel-offset fan-out (not a single "last `startPosition`," which only fits the sequential fallback).
- Edge cases: empty result sets, tables with no English translation (flag rather than silently returning Japanese-only labels), tables using area mesh codes instead of standard prefecture/municipality codes.

### M6 — Documentation & release
- pkgdown site.
- Vignettes: "Getting started" (key setup + first pull), "Finding the right table" (search + curated wrappers), "Working with time series across prefectures", "Understanding e-Stat's data model" (indicator/classification/area/time structure, since this trips up first-time users).
- README with the required e-Stat API credit line.
- CRAN submission checklist (`R CMD check --as-cran`, reverse dependency n/a for v1, examples wrapped in `\donttest{}` where they require a live appId).

### M7 — Geography / mapping (v2, deferred per your call above)
- Join tidy e-Stat output to prefecture/municipality boundary polygons for `geometry = TRUE`-style choropleth mapping, most likely by wrapping the existing `jpndistrict`/`jpmesh` packages rather than redistributing shapefiles directly (same "wrap `tigris`, don't rebuild it" pattern tidycensus uses).
- Only start this once M0–M6 are stable and real usage has validated which geographies matter most (prefecture vs. municipality vs. mesh).

## Testing strategy

- Record real API responses once (with a personal appId, outside CI) as fixtures using `httptest2`, then run the full unit test suite against those fixtures — no secrets needed in GitHub Actions, no flakiness from a government API being slow or down. **Confirm early that `httptest2` intercepts `req_perform_parallel()`** (see M2) — the parallel pagination fan-out is the one path most likely to escape offline mocking, and it must be testable in CI without a live appId. **Also scrub the `appId` out of recorded fixtures** (it's in the request URL) via an `httptest2` redactor before anything is committed.
- Separate, manually-triggered integration test job that does hit the live API, gated behind a repo secret `ESTAT_API_KEY`, run on a schedule (weekly) rather than every push, to catch upstream API drift without blocking normal CI.
- A small `bench`-based performance regression suite (large-table parsing, label joins, parallel pagination fan-out) run in CI so a future change can't silently regress speed without anyone noticing.

## Explicit non-goals for v1

- No geometry/mapping support (M7, deferred).
- No support for the Statistics Dashboard API (different base URL/spec entirely — could be a second backend later if there's demand for its simpler no-auth indicators).
- No write/dataset-registration endpoints (`postDataset` etc.) — read-only package.

## Suggested first prompt to hand Claude Code

Start at M0–M1 only, in one session: scaffold the package, set up `httr2`-based request/response handling with the `RESULT`-block error parsing described above, implement `estat_api_key()`, and get one working low-level call (`estat_stats_list()`) returning a tibble against a live table search — proves the auth + HTTP layer end-to-end before building the rest on top of it.

## Credential hygiene

- The appId is a secret. Never hard-code it in R scripts, commit it to git, or paste it into issues/PRs/chat you don't control.
- Local dev: store it in a `.Renviron` file (project-level or `~/.Renviron`) as `ESTAT_API_KEY=<key>`, loaded automatically by R at session start. Add `.Renviron` to `.gitignore` **before** the first commit — verify with `git check-ignore .Renviron`.
- CI/fixture recording: store it as a GitHub Actions repo secret (`ESTAT_API_KEY`), referenced in the workflow YAML, never printed to logs.
- `estat_api_key()` (M1) should never `print()`, `cat()`, or `message()` the key value, including in its own examples/docs.
- The `appId` travels in the request query string, so it can leak through channels beyond a `print()` call: error/condition objects that echo the request URL or the `PARAMETER` block, `httr2` verbose output / `last_request()`, and recorded `httptest2` fixtures. Redact it to `appId=<hidden>` at the response handler (M1) and via an `httptest2` redactor for fixtures (see Testing) — belt and suspenders, since a leaked key in an issue or CI log is the exact scenario the "just reissue it" note below exists for.
- Up to 3 appIds are allowed per e-Stat account — if a key is ever pasted somewhere it shouldn't be (chat, a public repo, a shared screenshot), the cheap fix is to delete and reissue it on the e-Stat mypage rather than trying to figure out if it leaked.

## Open items for you to decide before/at M0

- License (MIT is the tidyverse-ecosystem default; fine unless you have a reason otherwise).
- Whether this lives under your personal GitHub or an org.

Sources:
- [Statistics Dashboard API overview](https://dashboard.e-stat.go.jp/en/static/api)
- [e-Stat API — How to use API](https://www.e-stat.go.jp/api/en/api-dev/how_to_use)
- [e-Stat API — FAQ](https://www.e-stat.go.jp/api/en/api-dev/faq)
- [estatapi R package README](https://github.com/yutannihilation/estatapi/blob/master/README.en.md)
- [estatapi on CRAN](https://cran.r-project.org/web/packages/estatapi/estatapi.pdf)

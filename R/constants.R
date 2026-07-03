# Package-wide constants for the e-Stat API.

# Base host and API version. The e-Stat REST API is versioned in the path,
# e.g. https://api.e-stat.go.jp/rest/3.0/app/json/getStatsList
estat_base_url <- function() "https://api.e-stat.go.jp"
estat_api_version <- function() "3.0"

# Environment variable that holds the user's e-Stat appId.
estat_key_envvar <- "ESTAT_API_KEY"

# Minimum spacing between requests, in seconds. e-Stat documents no hard rate
# limit today, but this is a government server: we stay deliberately polite and
# make throttling the default, not an afterthought. Overridable via option.
estat_default_throttle <- 0.34 # ~3 requests/second

# Maximum number of concurrent in-flight requests for parallel page fan-out.
# "Parallel but polite": bounded concurrency that coexists with the throttle
# above, rather than firing every page at once at a government host.
estat_default_max_active <- 5L

# The e-Stat getStatsData endpoint caps a single response at 100,000 records.
estat_max_records_per_call <- 100000L

# Query parameter that carries the appId. Centralised so the response handler
# and the httptest2 redactor scrub exactly the same name.
estat_appid_param <- "appId"

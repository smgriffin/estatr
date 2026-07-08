# Set your e-Stat API key

Registers your e-Stat `appId` for the current session, and optionally
writes it to your `.Renviron` so it is available in future sessions. The
e-Stat API requires a free `appId`; obtain one at
<https://www.e-stat.go.jp/api/>.

## Usage

``` r
estat_api_key(key, install = FALSE, overwrite = FALSE)
```

## Arguments

- key:

  Your e-Stat `appId`, a string.

- install:

  If `TRUE`, write the key to `.Renviron` so it persists across
  sessions. Defaults to `FALSE` (session only).

- overwrite:

  If `TRUE`, replace an existing `ESTAT_API_KEY` entry in `.Renviron`.
  Ignored when `install = FALSE`.

## Value

Invisibly, the key (so it can be piped), though it is never printed.

## Details

The key is a secret. This function never prints it, and you should never
commit it to version control or paste it into issues. If a key is ever
exposed, delete and reissue it on the e-Stat mypage (up to 3 are allowed
per account).

## Examples

``` r
if (FALSE) { # \dontrun{
# Session only
estat_api_key("your-app-id")

# Persist for future sessions
estat_api_key("your-app-id", install = TRUE)
} # }
```

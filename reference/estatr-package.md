# estatr: Tidy Access to Japanese Government Statistics (e-Stat API)

A tidy, tidycensus-style interface to the Japanese government-wide
statistics catalog served by the e-Stat API
(<https://www.e-stat.go.jp/api/>). Wraps table search, classification
metadata, and data retrieval, decoding e-Stat's numeric codes into
human-readable labels and returning tibbles that pipe into the
tidyverse. Internals use 'data.table' for speed on large tables; output
is a plain tibble at the return boundary.

## See also

Useful links:

- <https://github.com/smgriffin/estatr>

- <https://smgriffin.github.io/estatr/>

- Report bugs at <https://github.com/smgriffin/estatr/issues>

## Author

**Maintainer**: Sean Griffin <bantam-lists-79@icloud.com>

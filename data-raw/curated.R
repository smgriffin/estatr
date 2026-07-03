# Generates R/sysdata.rda holding `.estatr_curated`: the internal lookup of
# curated shortcut tables (friendly key -> statsDataId). Hunting for the right
# statsDataId by hand is the main friction point e-Stat users hit, so a small
# curated set of "the table most people want first" is the biggest UX win.
#
# The three IDs with a statsDataId below were each verified to return data via
# get_estat() (2026-07-03). The two marked NA need a domain judgment call about
# which specific census table to feature and are intentionally left pending for
# review — estat_curated_tables() surfaces them as "not yet curated".
#
# Run with: source("data-raw/curated.R")

.estatr_curated <- tibble::tribble(
  ~key,                    ~statsDataId,  ~label_en,                                  ~label_ja,
  "labour_force_survey",   "0003005798",  "Labour Force Survey: population by activity","労働力調査 就業状態別15歳以上人口",
  "family_income_survey",  "0002070001",  "Family Income and Expenditure Survey",     "家計調査 家計収支編",
  "regional_statistics",   "0000010106",  "Social & demographic statistics by prefecture","社会・人口統計体系 都道府県データ",
  "population_census",     NA_character_, "Population Census (pending curation)",      "国勢調査",
  "economic_census",       NA_character_, "Economic Census (pending curation)",        "経済センサス"
)

usethis::use_data(.estatr_curated, internal = TRUE, overwrite = TRUE)

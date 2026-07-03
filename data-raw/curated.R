# Generates R/sysdata.rda holding `.estatr_curated`: the internal lookup of
# curated shortcut tables (friendly key -> statsDataId). Hunting for the right
# statsDataId by hand is the main friction point e-Stat users hit, so a small
# curated set of "the table most people want first" is the biggest UX win.
#
# Each statsDataId below was verified to return data via get_estat()
# (2026-07-03). population_census uses the 2020 Census (the last *complete*
# census; the 2025 speedy tabulation 0004050397 is newer but preliminary);
# economic_census uses the 2021 Economic Census (activity survey).
#
# Run with: source("data-raw/curated.R")

.estatr_curated <- tibble::tribble(
  ~key,                    ~statsDataId,  ~label_en,                                  ~label_ja,
  "labour_force_survey",   "0003005798",  "Labour Force Survey: population by activity","労働力調査 就業状態別15歳以上人口",
  "family_income_survey",  "0002070001",  "Family Income and Expenditure Survey",     "家計調査 家計収支編",
  "regional_statistics",   "0000010106",  "Social & demographic statistics by prefecture","社会・人口統計体系 都道府県データ",
  "population_census",     "0003433219",  "Population Census 2020: population by sex", "令和2年国勢調査 男女別人口",
  "economic_census",       "0004005652",  "Economic Census 2021: establishments by industry","令和3年経済センサス 産業別事業所数"
)

usethis::use_data(.estatr_curated, internal = TRUE, overwrite = TRUE)

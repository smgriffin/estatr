# Generates the designated-city lookup used to roll ward polygons up to their
# parent city (see R/boundaries.R). e-Stat boundary shapefiles carry only ward
# codes for the 20 ordinance-designated cities (政令指定都市); their parent-city
# 5-digit code (e.g. 札幌市 = 01100) appears nowhere in the data and must be
# derived by unioning the wards. e-Stat statistics, however, report these cities
# at BOTH ward and parent-city level, so we emit both polygons.
#
# Each row gives the parent 5-digit code + name and the inclusive ward-code range
# (as integers, for a robust range match rather than fragile code arithmetic --
# Osaka's wards span 27102-27128 and would not group by floor(code/10)).
# Tokyo's 23 special wards (13101-13123) are ordinary municipalities but are also
# aggregated by e-Stat as 特別区部 (13100), so they get the same treatment.
#
# Run with: source("data-raw/designated.R")

load("R/sysdata.rda") # keep the existing internal objects (.estatr_curated)

.estatr_designated <- tibble::tribble(
  ~parent_code, ~parent_name,          ~ward_min, ~ward_max,
  "01100",      "札幌市",              1101L,     1110L,
  "04100",      "仙台市",              4101L,     4105L,
  "11100",      "さいたま市",          11101L,    11110L,
  "12100",      "千葉市",              12101L,    12106L,
  "13100",      "東京都特別区部",      13101L,    13123L,
  "14100",      "横浜市",              14101L,    14118L,
  "14130",      "川崎市",              14131L,    14137L,
  "14150",      "相模原市",            14151L,    14153L,
  "15100",      "新潟市",              15101L,    15108L,
  "22100",      "静岡市",              22101L,    22103L,
  "22130",      "浜松市",              22131L,    22138L,
  "23100",      "名古屋市",            23101L,    23116L,
  "26100",      "京都市",              26101L,    26111L,
  "27100",      "大阪市",              27102L,    27128L,
  "27140",      "堺市",                27141L,    27147L,
  "28100",      "神戸市",              28101L,    28110L,
  "33100",      "岡山市",              33101L,    33104L,
  "34100",      "広島市",              34101L,    34108L,
  "40100",      "北九州市",            40101L,    40109L,
  "40130",      "福岡市",              40131L,    40137L,
  "43100",      "熊本市",              43101L,    43105L
)

usethis::use_data(.estatr_curated, .estatr_designated, internal = TRUE, overwrite = TRUE)

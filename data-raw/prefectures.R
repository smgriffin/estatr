# Generates `data/prefectures.rda`: the 47 Japanese prefectures with their
# JIS X 0401 codes and English/Japanese names, for joining and filtering e-Stat
# `area` codes without another API round-trip. The e-Stat area code for a whole
# prefecture is the 2-digit JIS code followed by "000" (e.g. Tokyo = 13000).
#
# Run with: source("data-raw/prefectures.R")

prefectures <- tibble::tribble(
  ~code, ~name_en,     ~name_ja,   ~region_en,
  "01",  "Hokkaido",   "北海道",   "Hokkaido",
  "02",  "Aomori",     "青森県",   "Tohoku",
  "03",  "Iwate",      "岩手県",   "Tohoku",
  "04",  "Miyagi",     "宮城県",   "Tohoku",
  "05",  "Akita",      "秋田県",   "Tohoku",
  "06",  "Yamagata",   "山形県",   "Tohoku",
  "07",  "Fukushima",  "福島県",   "Tohoku",
  "08",  "Ibaraki",    "茨城県",   "Kanto",
  "09",  "Tochigi",    "栃木県",   "Kanto",
  "10",  "Gunma",      "群馬県",   "Kanto",
  "11",  "Saitama",    "埼玉県",   "Kanto",
  "12",  "Chiba",      "千葉県",   "Kanto",
  "13",  "Tokyo",      "東京都",   "Kanto",
  "14",  "Kanagawa",   "神奈川県", "Kanto",
  "15",  "Niigata",    "新潟県",   "Chubu",
  "16",  "Toyama",     "富山県",   "Chubu",
  "17",  "Ishikawa",   "石川県",   "Chubu",
  "18",  "Fukui",      "福井県",   "Chubu",
  "19",  "Yamanashi",  "山梨県",   "Chubu",
  "20",  "Nagano",     "長野県",   "Chubu",
  "21",  "Gifu",       "岐阜県",   "Chubu",
  "22",  "Shizuoka",   "静岡県",   "Chubu",
  "23",  "Aichi",      "愛知県",   "Chubu",
  "24",  "Mie",        "三重県",   "Kansai",
  "25",  "Shiga",      "滋賀県",   "Kansai",
  "26",  "Kyoto",      "京都府",   "Kansai",
  "27",  "Osaka",      "大阪府",   "Kansai",
  "28",  "Hyogo",      "兵庫県",   "Kansai",
  "29",  "Nara",       "奈良県",   "Kansai",
  "30",  "Wakayama",   "和歌山県", "Kansai",
  "31",  "Tottori",    "鳥取県",   "Chugoku",
  "32",  "Shimane",    "島根県",   "Chugoku",
  "33",  "Okayama",    "岡山県",   "Chugoku",
  "34",  "Hiroshima",  "広島県",   "Chugoku",
  "35",  "Yamaguchi",  "山口県",   "Chugoku",
  "36",  "Tokushima",  "徳島県",   "Shikoku",
  "37",  "Kagawa",     "香川県",   "Shikoku",
  "38",  "Ehime",      "愛媛県",   "Shikoku",
  "39",  "Kochi",      "高知県",   "Shikoku",
  "40",  "Fukuoka",    "福岡県",   "Kyushu",
  "41",  "Saga",       "佐賀県",   "Kyushu",
  "42",  "Nagasaki",   "長崎県",   "Kyushu",
  "43",  "Kumamoto",   "熊本県",   "Kyushu",
  "44",  "Oita",       "大分県",   "Kyushu",
  "45",  "Miyazaki",   "宮崎県",   "Kyushu",
  "46",  "Kagoshima",  "鹿児島県", "Kyushu",
  "47",  "Okinawa",    "沖縄県",   "Kyushu"
)

# e-Stat whole-prefecture area code.
prefectures$area_code <- paste0(prefectures$code, "000")
prefectures <- prefectures[, c("code", "area_code", "name_en", "name_ja", "region_en")]

usethis::use_data(prefectures, overwrite = TRUE)

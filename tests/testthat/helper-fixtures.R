# Shared builders for synthetic e-Stat response bodies used across tests.

# One getStatsData VALUE row as a JSON object literal.
sd_value <- function(value, time = "2018000103", cat01 = "00", unit = "万人") {
  sprintf(
    '{"@tab":"06","@cat01":"%s","@area":"00000","@time":"%s","@unit":"%s","$":"%s"}',
    cat01, time, unit, value
  )
}

# A full getStatsData response body (as JSON) with a given set of VALUE rows and
# pagination fields. Includes a bundled CLASS_INF so get_estat() can decode.
sd_json <- function(values, total, to, next_key = NULL, status = 0L, notes = TRUE) {
  next_field <- if (is.null(next_key)) "" else sprintf(',"NEXT_KEY":%d', next_key)
  note_field <- if (notes) '"NOTE":[{"@char":"*","$":"分母が小さい"}],' else ""
  class_inf <- '"CLASS_INF":{"CLASS_OBJ":[
    {"@id":"tab","@name":"表章項目","CLASS":{"@code":"06","@name":"15歳以上人口","@unit":"万人"}},
    {"@id":"cat01","@name":"就業状態","CLASS":[{"@code":"00","@name":"総数"},{"@code":"12","@name":"労働力人口"}]},
    {"@id":"area","@name":"地域","CLASS":{"@code":"00000","@name":"全国"}},
    {"@id":"time","@name":"時間軸","CLASS":[{"@code":"2018000103","@name":"2018年1～3月期"}]}
  ]}'
  sprintf(
    '{"GET_STATS_DATA":{"RESULT":{"STATUS":%d,"ERROR_MSG":""},"STATISTICAL_DATA":{
      "RESULT_INF":{"TOTAL_NUMBER":%d,"FROM_NUMBER":1,"TO_NUMBER":%d%s},
      %s,
      "DATA_INF":{%s"VALUE":[%s]}}}}',
    status, total, to, next_field, class_inf, note_field,
    paste(values, collapse = ",")
  )
}

# Parse a JSON string into the list body shape estat_fetch_bodies would return.
parse_body <- function(json) jsonlite::fromJSON(json, simplifyVector = FALSE)

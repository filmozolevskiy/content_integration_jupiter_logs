connection: "clickhouse-jupiter"

# include all the views
include: "/views/**/*.view"

datagroup: jupiter_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: jupiter_default_datagroup

explore: jupiter_api_responses {
  label: "Jupiter API Responses"
}

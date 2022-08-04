view: jupiter_api_responses {
  sql_table_name: jupiter.jupiter_api_responses ;;

  dimension: action {
    type: string
    sql: ${TABLE}.action ;;
  }

  dimension: controller {
    type: string
    sql: ${TABLE}.controller ;;
  }

  dimension: duration {
    type: number
    sql: ${TABLE}.duration ;;
  }

  dimension: http_code {
    type: number
    sql: ${TABLE}.http_code ;;
  }

  dimension_group: timestamp {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.timestamp ;;
  }

  dimension: transaction_group_id {
    type: string
    sql: ${TABLE}.transaction_group_id ;;
  }

  dimension: username {
    type: string
    sql: ${TABLE}.username ;;
  }

  measure: count {
    type: count
    drill_fields: [controller, action, username, http_code, transaction_group_id, timestamp_raw, duration]
  }
}

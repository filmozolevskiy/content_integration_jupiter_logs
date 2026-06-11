# Row grain — one row per label emission in jupiter.jupiter_api_tags_v2.
# A single transaction_id emits many rows over its lifetime, bookended by
# 'miscellaneous:request_received' and 'miscellaneous:response_sent'.
view: jupiter_tags {
  sql_table_name: jupiter.jupiter_api_tags_v2 ;;

  dimension: pk {
    primary_key: yes
    hidden: yes
    sql: cityHash64(toString(${TABLE}.transaction_id), toString(${TABLE}.timestamp),
                    arrayStringConcat(${TABLE}.labels, '|')) ;;
  }

  dimension: transaction_id {
    type: string
    sql: toString(${TABLE}.transaction_id) ;;
  }

  dimension: username   { type: string  sql: ${TABLE}.username ;; }
  dimension: booking_id { type: number  sql: ${TABLE}.booking_id ;; }
  dimension: trip_id    { type: number  sql: ${TABLE}.trip_id ;; }

  dimension: labels_raw {
    type: string
    description: "Comma-joined labels for the row — full namespaced strings."
    sql: arrayStringConcat(${TABLE}.labels, ', ') ;;
  }

  dimension_group: timestamp {
    type: time
    timeframes: [raw, time, date, hour, week, month]
    sql: ${TABLE}.timestamp ;;
  }

  # One dimension per documented label namespace. arrayFirst returns '' when absent.
  dimension: action {
    description: "Endpoint: check / calculate / process."
    sql: substring(arrayFirst(x -> startsWith(x, 'action:'), ${TABLE}.labels), 8) ;;
  }
  dimension: service {
    sql: substring(arrayFirst(x -> startsWith(x, 'service:'), ${TABLE}.labels), 9) ;;
  }
  dimension: context {
    sql: substring(arrayFirst(x -> startsWith(x, 'context:'), ${TABLE}.labels), 9) ;;
  }
  dimension: option_type {
    description: "Cancellation option type, e.g. cancel/refund, cancel/void."
    sql: substring(arrayFirst(x -> startsWith(x, 'option_type:'), ${TABLE}.labels), 13) ;;
  }
  dimension: serviceability_indicator {
    description: "Engine's verdict: is_valid / is_quoted / should_calculate / is_automated / etc."
    sql: substring(arrayFirst(x -> startsWith(x, 'serviceability_indicator:'), ${TABLE}.labels), 26) ;;
  }
  dimension: serviceability_reason {
    description: "Why the engine refused: escalate / cannot_be_refunded / call_us / etc."
    sql: substring(arrayFirst(x -> startsWith(x, 'serviceability_reason:'), ${TABLE}.labels), 23) ;;
  }
  dimension: task_type {
    sql: substring(arrayFirst(x -> startsWith(x, 'task_type:'), ${TABLE}.labels), 11) ;;
  }
  dimension: work_order {
    sql: substring(arrayFirst(x -> startsWith(x, 'work_order:'), ${TABLE}.labels), 12) ;;
  }
  dimension: force {
    sql: substring(arrayFirst(x -> startsWith(x, 'force:'), ${TABLE}.labels), 7) ;;
  }
  dimension: error {
    sql: substring(arrayFirst(x -> startsWith(x, 'error:'), ${TABLE}.labels), 7) ;;
  }
  dimension: miscellaneous {
    description: "request_received / response_sent / request_sent."
    sql: substring(arrayFirst(x -> startsWith(x, 'miscellaneous:'), ${TABLE}.labels), 15) ;;
  }

  measure: count              { type: count }
  measure: count_transactions { type: count_distinct  sql: ${transaction_id} ;; }
  measure: count_bookings     { type: count_distinct  sql: ${booking_id} ;; }
}

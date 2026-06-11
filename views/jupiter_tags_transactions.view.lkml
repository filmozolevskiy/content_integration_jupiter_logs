# Transaction grain — one row per transaction_id (one Jupiter API HTTP request).
# Used for N1 automation rate (process-bounded).
view: jupiter_tags_transactions {
  derived_table: {
    datagroup_trigger: jupiter_tags_default
    sql:
      SELECT
        transaction_id,
        any(username)   AS username,
        any(booking_id) AS booking_id,
        any(trip_id)    AS trip_id,
        substring(
          arrayFirst(x -> startsWith(x, 'action:'), groupUniqArrayArray(labels)),
          8
        ) AS action,
        min(timestamp) AS started_at,
        max(timestamp) AS ended_at,
        dateDiff('millisecond', min(timestamp), max(timestamp)) AS duration_ms,
        has(groupUniqArrayArray(labels), 'miscellaneous:request_received')          AS has_request_received,
        has(groupUniqArrayArray(labels), 'miscellaneous:response_sent')             AS has_response_sent,
        arrayExists(x -> startsWith(x, 'error:'), groupUniqArrayArray(labels))      AS has_error,
        has(groupUniqArrayArray(labels), 'serviceability_indicator:is_automated')     AS is_automated,
        has(groupUniqArrayArray(labels), 'serviceability_indicator:is_not_automated') AS is_not_automated,
        arrayStringConcat(
          arrayFilter(x -> startsWith(x, 'option_type:'), groupUniqArrayArray(labels)),
          ', '
        ) AS option_types,
        arrayStringConcat(
          arrayFilter(x -> startsWith(x, 'task_type:'), groupUniqArrayArray(labels)),
          ', '
        ) AS task_types,
        arrayStringConcat(
          arrayFilter(x -> startsWith(x, 'work_order:'), groupUniqArrayArray(labels)),
          ', '
        ) AS work_orders,
        arrayStringConcat(
          arrayFilter(x -> startsWith(x, 'error:'), groupUniqArrayArray(labels)),
          ', '
        ) AS errors
      FROM jupiter.jupiter_api_tags_v2
      WHERE {% condition started_date %} timestamp {% endcondition %}
      GROUP BY transaction_id
    ;;
  }

  dimension: transaction_id {
    primary_key: yes
    type: string
    sql: toString(${TABLE}.transaction_id) ;;
  }

  dimension: action     { type: string  sql: ${TABLE}.action ;; }
  dimension: booking_id { type: number  sql: ${TABLE}.booking_id ;; }
  dimension: trip_id    { type: number  sql: ${TABLE}.trip_id ;; }
  dimension: username   { type: string  sql: ${TABLE}.username ;; }

  dimension_group: started {
    type: time
    timeframes: [raw, time, date, hour, week, month]
    sql: ${TABLE}.started_at ;;
  }
  dimension_group: ended {
    type: time
    timeframes: [raw, time, date, hour, week, month]
    sql: ${TABLE}.ended_at ;;
  }

  dimension: duration_ms {
    description: "Time between first and last tag for the transaction. Proxy for cancel-engine internal time, not true HTTP latency."
    type: number
    sql: ${TABLE}.duration_ms ;;
  }

  dimension: has_request_received { type: yesno  sql: ${TABLE}.has_request_received ;; }
  dimension: has_response_sent    { type: yesno  sql: ${TABLE}.has_response_sent ;; }
  dimension: is_completed {
    description: "Transaction emitted both request_received and response_sent."
    type: yesno
    sql: ${has_request_received} AND ${has_response_sent} ;;
  }
  dimension: has_error        { type: yesno  sql: ${TABLE}.has_error ;; }
  dimension: is_automated     { type: yesno  sql: ${TABLE}.is_automated ;; }
  dimension: is_not_automated { type: yesno  sql: ${TABLE}.is_not_automated ;; }

  dimension: option_types { type: string  sql: ${TABLE}.option_types ;; }
  dimension: task_types   { type: string  sql: ${TABLE}.task_types ;; }
  dimension: work_orders  { type: string  sql: ${TABLE}.work_orders ;; }
  dimension: errors       { type: string  sql: ${TABLE}.errors ;; }

  measure: count_transactions          { type: count }
  measure: count_process_transactions  { type: count  filters: [action: "process"] }
  measure: count_automated_process     { type: count  filters: [action: "process", is_automated: "yes"] }
  measure: count_manual_process        { type: count  filters: [action: "process", is_not_automated: "yes"] }

  # N1 — process-bounded automation rate
  measure: automation_rate_n1 {
    description: "N1: of process transactions tagged automated-or-manual, share automated."
    type: number
    sql: 1.0 * ${count_automated_process} / nullIf(${count_automated_process} + ${count_manual_process}, 0) ;;
    value_format_name: percent_1
  }

  measure: avg_duration_ms { type: average  sql: ${duration_ms} ;;  value_format_name: decimal_0 }
  measure: p95_duration_ms { type: percentile  percentile: 95  sql: ${duration_ms} ;;  value_format_name: decimal_0 }
}

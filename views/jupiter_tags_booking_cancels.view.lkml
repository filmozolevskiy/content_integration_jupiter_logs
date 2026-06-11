# Booking grain — one row per booking_id over its full cancel attempt history.
# Used for N2, N3 automation rates and the terminal-state mix
# (automated / manual_via_mvai / handed_off / in_progress).
view: jupiter_tags_booking_cancels {
  derived_table: {
    datagroup_trigger: jupiter_tags_default
    sql:
      WITH per_booking AS (
        SELECT
          booking_id,
          any(trip_id) AS trip_id,
          min(timestamp) AS first_event_at,
          max(timestamp) AS last_event_at,
          groupUniqArrayArray(labels) AS all_labels,
          groupUniqArray(
            substring(arrayFirst(x -> startsWith(x, 'action:'), labels), 8)
          ) AS actions_seen
        FROM jupiter.jupiter_api_tags_v2
        WHERE {% condition first_event_date %} timestamp {% endcondition %}
          AND booking_id > 0
        GROUP BY booking_id
      )
      SELECT
        booking_id,
        trip_id,
        first_event_at,
        last_event_at,
        has(actions_seen, 'check')     AS reached_check,
        has(actions_seen, 'calculate') AS reached_calculate,
        has(actions_seen, 'process')   AS reached_process,
        has(all_labels, 'serviceability_indicator:is_valid')         AS check_returned_valid,
        has(all_labels, 'serviceability_indicator:is_automated')     AS process_automated,
        has(all_labels, 'serviceability_indicator:is_not_automated') AS process_manual,
        arrayExists(x -> x IN (
          'serviceability_reason:escalate',
          'serviceability_reason:call_us',
          'serviceability_reason:call_airline',
          'serviceability_reason:redirect_to_airline_website'
        ), all_labels) AS check_handed_off,
        multiIf(
          has(all_labels, 'serviceability_indicator:is_automated'),     'automated',
          has(all_labels, 'serviceability_indicator:is_not_automated'), 'manual_via_mvai',
          arrayExists(x -> x IN (
            'serviceability_reason:escalate',
            'serviceability_reason:call_us',
            'serviceability_reason:call_airline',
            'serviceability_reason:redirect_to_airline_website'
          ), all_labels), 'handed_off',
          'in_progress'
        ) AS terminal_state,
        arrayStringConcat(
          arrayFilter(x -> startsWith(x, 'option_type:'), all_labels),
          ', '
        ) AS option_types_seen,
        arrayStringConcat(
          arrayFilter(x -> startsWith(x, 'error:'), all_labels),
          ', '
        ) AS errors_seen
      FROM per_booking
    ;;
  }

  dimension: booking_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.booking_id ;;
  }

  dimension: trip_id { type: number  sql: ${TABLE}.trip_id ;; }

  dimension_group: first_event {
    type: time
    timeframes: [raw, time, date, hour, week, month]
    sql: ${TABLE}.first_event_at ;;
  }
  dimension_group: last_event {
    type: time
    timeframes: [raw, time, date, hour, week, month]
    sql: ${TABLE}.last_event_at ;;
  }

  dimension: reached_check        { type: yesno  sql: ${TABLE}.reached_check ;; }
  dimension: reached_calculate    { type: yesno  sql: ${TABLE}.reached_calculate ;; }
  dimension: reached_process      { type: yesno  sql: ${TABLE}.reached_process ;; }
  dimension: check_returned_valid {
    description: "At least one cancel option came back is_valid from the check endpoint."
    type: yesno
    sql: ${TABLE}.check_returned_valid ;;
  }
  dimension: process_automated { type: yesno  sql: ${TABLE}.process_automated ;; }
  dimension: process_manual    { type: yesno  sql: ${TABLE}.process_manual ;; }
  dimension: check_handed_off  { type: yesno  sql: ${TABLE}.check_handed_off ;; }

  dimension: terminal_state {
    description: "automated / manual_via_mvai / handed_off / in_progress (β bucketing)."
    type: string
    sql: ${TABLE}.terminal_state ;;
  }

  dimension: option_types_seen { type: string  sql: ${TABLE}.option_types_seen ;; }
  dimension: errors_seen       { type: string  sql: ${TABLE}.errors_seen ;; }

  measure: count_bookings        { type: count }
  measure: count_reached_check   { type: count  filters: [reached_check: "yes"] }
  measure: count_reached_process { type: count  filters: [reached_process: "yes"] }
  measure: count_check_valid     { type: count  filters: [check_returned_valid: "yes"] }
  measure: count_automated       { type: count  filters: [process_automated: "yes"] }
  measure: count_manual_via_mvai { type: count  filters: [process_manual: "yes", process_automated: "no"] }
  measure: count_handed_off      { type: count  filters: [terminal_state: "handed_off"] }
  measure: count_in_progress     { type: count  filters: [terminal_state: "in_progress"] }

  # N2 — booking-attempt-bounded
  measure: automation_rate_n2 {
    description: "N2: of every booking MVAI saw, share resolved automatically end-to-end."
    type: number
    sql: 1.0 * ${count_automated} / nullIf(${count_bookings}, 0) ;;
    value_format_name: percent_1
  }

  # N3 — checked-as-valid-bounded (headline)
  measure: automation_rate_n3 {
    description: "N3 (headline): of bookings where check returned a valid option, share auto-completed."
    type: number
    sql: 1.0 * ${count_automated} / nullIf(${count_check_valid}, 0) ;;
    value_format_name: percent_1
  }
}

view: jupiter_api_logs {

  # Direct table reference - filters will be pushed down to database level
  sql_table_name: jupiter.jupiter_api_logs ;;

  # Computed ID dimension
  dimension: id {
    type: string
    sql: toString(${TABLE}.timestamp) || '_' || toString(cityHash64(${TABLE}.request)) || '_' || toString(cityHash64(${TABLE}.response)) ;;
    primary_key: yes
    hidden: yes
  }

  # -------------------------
  # 1. Basic Dimensions
  # -------------------------

  dimension: controller {
    type: string
    sql: ${TABLE}.controller ;;
    group_label: "1. Basic Dimensions"
    label: "Controller"
    description: "Controller name handling the API request"
  }

  dimension: action {
    type: string
    sql: ${TABLE}.action ;;
    group_label: "1. Basic Dimensions"
    label: "Action"
    description: "Action name within the controller"
    suggestions: ["abort", "add", "calculate", "check", "create", "make-primary", "process", "quote", "replace-date-of-birth", "replace-disability-indicators", "replace-gender", "rules", "search", "trip-serviceability"]
  }

  dimension: username {
    type: string
    sql: ${TABLE}.username ;;
    group_label: "1. Basic Dimensions"
    label: "Username"
    description: "Username associated with the API request"
    hidden: yes
  }

  dimension: http_code {
    type: number
    sql: ${TABLE}.http_code ;;
    group_label: "1. Basic Dimensions"
    label: "Status"
    description: "HTTP status code from the table"
  }

  dimension: transaction_group_id {
    type: string
    sql: ${TABLE}.transaction_group_id ;;
    group_label: "1. Basic Dimensions"
    label: "Transaction Group ID"
    description: "Transaction group identifier for grouping related requests"
  }

  dimension: transaction_group_link {
    type: string
    sql: ${transaction_group_id} ;;
    html: <a href="https://reservations.voyagesalacarte.ca/jupiter/log-group/{{ value }}" target="_blank">{{ rendered_value }}</a> ;;
    group_label: "1. Basic Dimensions"
    label: "Transaction Group Link"
    description: "Clickable link to view transaction group details"
  }

  dimension: timestamp_raw {
    type: string
    sql: toString(${TABLE}.timestamp) ;;
    group_label: "1. Basic Dimensions"
    label: "Timestamp Raw"
    description: "Raw timestamp value as string"
  }

  dimension_group: timestamp {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.timestamp ;;
    group_label: "1. Basic Dimensions"
    label: "Timestamp"
    description: "Group of time-based dimensions for log entry timestamp"
  }

  # -------------------------
  # 2. Request Dimensions
  # -------------------------

  dimension: request_method {
    type: string
    sql: JSONExtractString(${TABLE}.request, 'method') ;;
    group_label: "2. Request Dimensions"
    label: "Method"
    description: "HTTP method from the request (GET, POST, etc.)"
    hidden: yes
  }

  dimension: request_host {
    type: string
    sql: JSONExtractString(${TABLE}.request, 'host') ;;
    group_label: "2. Request Dimensions"
    label: "Host"
    description: "Host name from the request"
  }

  dimension: request_path {
    type: string
    sql: JSONExtractString(${TABLE}.request, 'path') ;;
    group_label: "2. Request Dimensions"
    label: "Path"
    description: "API path from the request"
    hidden: yes
  }

  dimension: request_x_request_id {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.request, 'headers'), 'x-request-id') ;;
    group_label: "2. Request Dimensions"
    label: "Request ID"
    description: "Request ID from request headers (x-request-id)"
    hidden: yes
  }

  dimension: request_user_agent {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.request, 'headers'), 'user-agent') ;;
    group_label: "2. Request Dimensions"
    label: "User Agent"
    description: "User agent string from request headers"
    hidden: yes
  }

  dimension: request_accept {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.request, 'headers'), 'accept') ;;
    group_label: "2. Request Dimensions"
    label: "Accept"
    description: "Accept header from request headers"
    hidden: yes
  }

  dimension: request_x_geo_country_code {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.request, 'headers'), 'x-geo-country-code') ;;
    group_label: "2. Request Dimensions"
    label: "Country Code"
    description: "Country code from geo headers (x-geo-country-code)"
    hidden: yes
  }

  dimension: request_x_geo_country_name {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.request, 'headers'), 'x-geo-country-name') ;;
    group_label: "2. Request Dimensions"
    label: "Country Name"
    description: "Country name from geo headers (x-geo-country-name)"
  }

  dimension: request_x_geo_city {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.request, 'headers'), 'x-geo-city') ;;
    group_label: "2. Request Dimensions"
    label: "City"
    description: "City from geo headers (x-geo-city)"
    hidden: yes
  }

  dimension: request_x_geo_isp {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.request, 'headers'), 'x-geo-isp') ;;
    group_label: "2. Request Dimensions"
    label: "ISP"
    description: "ISP from geo headers (x-geo-isp)"
    hidden: yes
  }

  dimension: request_x_geo_connection_type {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.request, 'headers'), 'x-geo-connection-type') ;;
    group_label: "2. Request Dimensions"
    label: "Connection Type"
    description: "Connection type from geo headers (x-geo-connection-type)"
    hidden: yes
  }

  dimension: request_query {
    type: string
    sql: JSONExtractRaw(${TABLE}.request, 'query') ;;
    group_label: "2. Request Dimensions"
    label: "Query"
    description: "Query parameters from request (JSON array)"
    hidden: yes
  }

  dimension: request_form {
    type: string
    sql: JSONExtractRaw(${TABLE}.request, 'form') ;;
    group_label: "2. Request Dimensions"
    label: "Form"
    description: "Form data from request (JSON array)"
    hidden: yes
  }

  dimension: request_json {
    type: string
    sql: JSONExtractRaw(${TABLE}.request, 'json') ;;
    group_label: "2. Request Dimensions"
    label: "JSON"
    description: "JSON body from request (JSON array)"
  }

  dimension: request_booking_id {
    type: number
    sql: COALESCE(
            if(length(JSONExtractArrayRaw(JSONExtractRaw(${TABLE}.request, 'json'), 'parameters')) > 0,
               toInt64OrZero(JSONExtractString(JSONExtractArrayRaw(JSONExtractRaw(${TABLE}.request, 'json'), 'parameters')[1], 'bookingId')),
               0),
            toInt64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.request, 'json'), 'tripItineraryChanges'), 'bookingId')),
            0
          ) ;;
    group_label: "2. Request Dimensions"
    label: "Booking ID"
    description: "Booking ID from request (extracted from json.parameters[0].bookingId or json.tripItineraryChanges.bookingId)"
  }

  dimension: request_raw {
    type: string
    sql: toString(${TABLE}.request) ;;
    group_label: "2. Request Dimensions"
    label: "Request Raw"
    description: "Complete raw request JSON structure"
  }

  # -------------------------
  # 3. Response Meta Dimensions
  # -------------------------

  dimension: response_status {
    type: number
    sql: toInt32OrZero(JSONExtractString(${TABLE}.response, 'status')) ;;
    group_label: "3. Response Meta Dimensions"
    label: "Status"
    description: "HTTP status code from response"
    hidden: yes
  }

  dimension: response_content_type {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.response, 'headers'), 'content-type') ;;
    group_label: "3. Response Meta Dimensions"
    label: "Content Type"
    description: "Content type from response headers"
    hidden: yes
  }

  dimension: response_x_execution_time {
    type: number
    sql: if(JSONHas(JSONExtractRaw(${TABLE}.response, 'headers'), 'x-execution-time'),
            toFloat64OrZero(JSONExtractString(JSONExtractRaw(${TABLE}.response, 'headers'), 'x-execution-time')),
            0.0) ;;
    value_format_name: decimal_4
    group_label: "3. Response Meta Dimensions"
    label: "Execution Time"
    description: "Execution time in seconds from response headers (x-execution-time)"
  }

  dimension: response_x_memory_peak_usage {
    type: string
    sql: if(JSONHas(JSONExtractRaw(${TABLE}.response, 'headers'), 'x-memory-peak-usage'),
            JSONExtractString(JSONExtractRaw(${TABLE}.response, 'headers'), 'x-memory-peak-usage'),
            NULL) ;;
    group_label: "3. Response Meta Dimensions"
    label: "Memory Peak Usage"
    description: "Memory peak usage from response headers (x-memory-peak-usage)"
    hidden: yes
  }

  dimension: response_x_momentum_api_authorization {
    type: string
    sql: if(JSONHas(JSONExtractRaw(${TABLE}.response, 'headers'), 'x-momentum-api-authorization'),
            JSONExtractString(JSONExtractRaw(${TABLE}.response, 'headers'), 'x-momentum-api-authorization'),
            NULL) ;;
    group_label: "3. Response Meta Dimensions"
    label: "API Authorization"
    description: "API authorization type from response headers (x-momentum-api-authorization)"
    hidden: yes
  }

  dimension: is_success {
    type: yesno
    sql: ifNull(${response_status}, 0) >= 200 AND ifNull(${response_status}, 0) < 300 ;;
    group_label: "3. Response Meta Dimensions"
    label: "Is Success"
    description: "Whether the response status indicates success (2xx)"
  }

  dimension: is_error {
    type: yesno
    sql: ifNull(${response_status}, 0) >= 400 ;;
    group_label: "3. Response Meta Dimensions"
    label: "Is Error"
    description: "Whether the response status indicates an error (4xx or 5xx)"
  }

  dimension: response_raw {
    type: string
    sql: toString(${TABLE}.response) ;;
    group_label: "3. Response Meta Dimensions"
    label: "Response Raw"
    description: "Complete raw response JSON structure"
  }

  # -------------------------
  # 4. Response Data Dimensions
  # -------------------------

  dimension: response_booking_id {
    type: number
    sql: if(length(JSONExtractArrayRaw(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'body'), 'data'))) > 0,
            toInt64OrZero(JSONExtractString(JSONExtractArrayRaw(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'body'), 'data'))[1], 'bookingId')),
            0) ;;
    group_label: "4. Response Data Dimensions"
    label: "Booking ID"
    description: "Booking ID from successful response data"
  }

  # -------------------------
  # 5. Response Error Dimensions
  # -------------------------

  dimension: error_code {
    type: number
    sql: toInt32OrZero(JSONExtractString(JSONExtractRaw(${TABLE}.response, 'body'), 'error_code')) ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Code"
    description: "Error code from error response body"
  }

  dimension: error_message {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.response, 'body'), 'error_message') ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Message"
    description: "Error message from error response body"
  }

  dimension: error_details_booking_id {
    type: number
    sql: toInt64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'body'), 'error_details'), 'bookingId')) ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Details Booking ID"
    description: "Booking ID from error details (if present)"
  }

  dimension: error_details_passenger_id {
    type: number
    sql: toInt64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'body'), 'error_details'), 'passengerId')) ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Details Passenger ID"
    description: "Passenger ID from error details (if present)"
  }

  dimension: error_details_work_order_type {
    type: string
    sql: JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'body'), 'error_details'), 'workOrderType') ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Details Work Order Type"
    description: "Work order type from error details (if present)"
  }

  dimension: error_details_reason {
    type: string
    sql: JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'body'), 'error_details'), 'reason') ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Details Reason"
    description: "Reason from error details (if present)"
  }

  dimension: error_details_error {
    type: string
    sql: JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'body'), 'error_details'), 'error') ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Details Error"
    description: "Error details message (if present)"
  }

  # -------------------------
  # 6. Measures
  # -------------------------

  measure: count {
    type: count
    group_label: "6. Measures"
    label: "Count"
    description: "Total count of log entries"
  }

  measure: count_success {
    type: count
    filters: [is_success: "yes"]
    group_label: "6. Measures"
    label: "Count Success"
    description: "Count of successful responses (status 2xx)"
  }

  measure: count_error {
    type: count
    filters: [is_error: "yes"]
    group_label: "6. Measures"
    label: "Count Error"
    description: "Count of error responses (status 4xx/5xx)"
  }

  measure: success_rate {
    type: number
    sql: ${count_success} / NULLIF(${count}, 0) * 100.0 ;;
    value_format_name: decimal_2
    group_label: "6. Measures"
    label: "Success Rate"
    description: "Percentage of successful responses"
  }

  measure: average_execution_time {
    type: average
    sql: ${response_x_execution_time} ;;
    filters: [response_x_execution_time: ">0"]
    value_format_name: decimal_4
    group_label: "6. Measures"
    label: "Average Execution Time"
    description: "Average execution time in seconds from response headers (excluding NULLs)"
  }

  measure: total_execution_time {
    type: sum
    sql: ${response_x_execution_time} ;;
    filters: [response_x_execution_time: ">0"]
    value_format_name: decimal_4
    group_label: "6. Measures"
    label: "Total Execution Time"
    description: "Sum of execution times in seconds (excluding NULLs)"
  }

  measure: max_execution_time {
    type: number
    sql: MAX(CASE WHEN ${response_x_execution_time} > 0 THEN ${response_x_execution_time} ELSE NULL END) ;;
    value_format_name: decimal_4
    group_label: "6. Measures"
    label: "Max Execution Time"
    description: "Maximum execution time in seconds (excluding NULLs and zeros)"
  }

  measure: min_execution_time {
    type: number
    sql: MIN(CASE WHEN ${response_x_execution_time} > 0 THEN ${response_x_execution_time} ELSE NULL END) ;;
    value_format_name: decimal_4
    group_label: "6. Measures"
    label: "Min Execution Time"
    description: "Minimum execution time in seconds (excluding NULLs and zeros)"
  }

  measure: distinct_controllers {
    type: count_distinct
    sql: ${controller} ;;
    group_label: "6. Measures"
    label: "Distinct Controllers"
    description: "Distinct count of controller names"
  }

  measure: distinct_actions {
    type: count_distinct
    sql: ${action} ;;
    group_label: "6. Measures"
    label: "Distinct Actions"
    description: "Distinct count of action names"
  }

  measure: distinct_usernames {
    type: count_distinct
    sql: ${username} ;;
    group_label: "6. Measures"
    label: "Distinct Usernames"
    description: "Distinct count of usernames"
  }

  measure: distinct_request_paths {
    type: count_distinct
    sql: ${request_path} ;;
    group_label: "6. Measures"
    label: "Distinct Request Paths"
    description: "Distinct count of API paths"
  }

  measure: distinct_transaction_groups {
    type: count_distinct
    sql: ${transaction_group_id} ;;
    group_label: "6. Measures"
    label: "Distinct Transaction Groups"
    description: "Distinct count of transaction group IDs"
  }

  measure: count_by_error_code {
    type: count
    filters: [error_code: ">0"]
    group_label: "6. Measures"
    label: "Count by Error Code"
    description: "Count of records with error codes"
  }

  measure: count_by_error_message {
    type: count
    filters: [error_message: "!="]
    group_label: "6. Measures"
    label: "Count by Error Message"
    description: "Count of records with error messages"
  }

}

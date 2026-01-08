view: jupiter_api_logs {

  # Derived Table with CTEs for JSON extraction
  # base_cte computes ID once and includes request/response JSON for other CTEs to extract from
  derived_table: {
    sql:
      WITH base_cte AS (
        SELECT
          toString(timestamp) || '_' || toString(cityHash64(request)) || '_' || toString(cityHash64(response)) AS id,
          controller,
          action,
          username,
          http_code,
          transaction_group_id,
          timestamp,
          request,
          response
        FROM jupiter.jupiter_api_logs
        WHERE timestamp > now() - interval 1 month
      ),
      request_cte AS (
        SELECT
          id,
          JSONExtractString(request, 'method') AS request_method,
          JSONExtractString(request, 'host') AS request_host,
          JSONExtractString(request, 'path') AS request_path,
          JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-request-id') AS request_x_request_id,
          JSONExtractString(JSONExtractRaw(request, 'headers'), 'user-agent') AS request_user_agent,
          JSONExtractString(JSONExtractRaw(request, 'headers'), 'accept') AS request_accept,
          JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-geo-country-code') AS request_x_geo_country_code,
          JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-geo-country-name') AS request_x_geo_country_name,
          JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-geo-city') AS request_x_geo_city,
          JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-geo-isp') AS request_x_geo_isp,
          JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-geo-connection-type') AS request_x_geo_connection_type,
          JSONExtractRaw(request, 'query') AS request_query,
          JSONExtractRaw(request, 'form') AS request_form,
          JSONExtractRaw(request, 'json') AS request_json
        FROM base_cte
      ),
      response_meta_cte AS (
        SELECT
          id,
          toInt32OrZero(JSONExtractString(response, 'status')) AS response_status,
          JSONExtractString(JSONExtractRaw(response, 'headers'), 'content-type') AS response_content_type,
          if(JSONHas(JSONExtractRaw(response, 'headers'), 'x-execution-time'),
             toFloat64OrZero(JSONExtractString(JSONExtractRaw(response, 'headers'), 'x-execution-time')),
             0.0) AS response_x_execution_time,
          if(JSONHas(JSONExtractRaw(response, 'headers'), 'x-memory-peak-usage'),
             JSONExtractString(JSONExtractRaw(response, 'headers'), 'x-memory-peak-usage'),
             NULL) AS response_x_memory_peak_usage,
          if(JSONHas(JSONExtractRaw(response, 'headers'), 'x-momentum-api-authorization'),
             JSONExtractString(JSONExtractRaw(response, 'headers'), 'x-momentum-api-authorization'),
             NULL) AS response_x_momentum_api_authorization
        FROM base_cte
        WHERE JSONHas(response, 'status')
      ),
      response_body_data_cte AS (
        SELECT
          id,
          if(length(JSONExtractArrayRaw(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'data'))) > 0,
             toInt64OrZero(JSONExtractString(JSONExtractArrayRaw(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'data'))[1], 'bookingId')),
             0) AS response_booking_id
        FROM base_cte
        WHERE JSONHas(response, 'body') AND JSONHas(JSONExtractRaw(response, 'body'), 'data')
      ),
      response_body_error_cte AS (
        SELECT
          id,
          toInt32OrZero(JSONExtractString(JSONExtractRaw(response, 'body'), 'error_code')) AS error_code,
          JSONExtractString(JSONExtractRaw(response, 'body'), 'error_message') AS error_message,
          toInt64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'error_details'), 'bookingId')) AS error_details_booking_id,
          toInt64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'error_details'), 'passengerId')) AS error_details_passenger_id,
          JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'error_details'), 'workOrderType') AS error_details_work_order_type,
          JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'error_details'), 'reason') AS error_details_reason,
          JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'error_details'), 'error') AS error_details_error
        FROM base_cte
        WHERE JSONHas(response, 'body') AND JSONHas(JSONExtractRaw(response, 'body'), 'error_code')
      )
      SELECT
        b.id,
        b.controller,
        b.action,
        b.username,
        b.http_code,
        b.transaction_group_id,
        b.timestamp,
        r.request_method,
        r.request_host,
        r.request_path,
        r.request_x_request_id,
        r.request_user_agent,
        r.request_accept,
        r.request_x_geo_country_code,
        r.request_x_geo_country_name,
        r.request_x_geo_city,
        r.request_x_geo_isp,
        r.request_x_geo_connection_type,
        r.request_query,
        r.request_form,
        r.request_json,
        rm.response_status,
        rm.response_content_type,
        rm.response_x_execution_time,
        rm.response_x_memory_peak_usage,
        rm.response_x_momentum_api_authorization,
        rbd.response_booking_id,
        rbe.error_code,
        rbe.error_message,
        rbe.error_details_booking_id,
        rbe.error_details_passenger_id,
        rbe.error_details_work_order_type,
        rbe.error_details_reason,
        rbe.error_details_error
      FROM base_cte b
      LEFT JOIN request_cte r ON b.id = r.id
      LEFT JOIN response_meta_cte rm ON b.id = rm.id
      LEFT JOIN response_body_data_cte rbd ON b.id = rbd.id
      LEFT JOIN response_body_error_cte rbe ON b.id = rbe.id
    ;;
  }

  dimension: id {
    type: string
    sql: ${TABLE}.id ;;
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
  }

  dimension: username {
    type: string
    sql: ${TABLE}.username ;;
    group_label: "1. Basic Dimensions"
    label: "Username"
    description: "Username associated with the API request"
  }

  dimension: http_code {
    type: number
    sql: ${TABLE}.http_code ;;
    group_label: "1. Basic Dimensions"
    label: "HTTP Code"
    description: "HTTP status code from the table"
  }

  dimension: transaction_group_id {
    type: string
    sql: ${TABLE}.transaction_group_id ;;
    group_label: "1. Basic Dimensions"
    label: "Transaction Group ID"
    description: "Transaction group identifier for grouping related requests"
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
    sql: ${TABLE}.request_method ;;
    group_label: "2. Request Dimensions"
    label: "Method"
    description: "HTTP method from the request (GET, POST, etc.)"
  }

  dimension: request_host {
    type: string
    sql: ${TABLE}.request_host ;;
    group_label: "2. Request Dimensions"
    label: "Host"
    description: "Host name from the request"
  }

  dimension: request_path {
    type: string
    sql: ${TABLE}.request_path ;;
    group_label: "2. Request Dimensions"
    label: "Path"
    description: "API path from the request"
  }

  dimension: request_x_request_id {
    type: string
    sql: ${TABLE}.request_x_request_id ;;
    group_label: "2. Request Dimensions"
    label: "Request ID"
    description: "Request ID from request headers (x-request-id)"
  }

  dimension: request_user_agent {
    type: string
    sql: ${TABLE}.request_user_agent ;;
    group_label: "2. Request Dimensions"
    label: "User Agent"
    description: "User agent string from request headers"
  }

  dimension: request_accept {
    type: string
    sql: ${TABLE}.request_accept ;;
    group_label: "2. Request Dimensions"
    label: "Accept"
    description: "Accept header from request headers"
  }

  dimension: request_x_geo_country_code {
    type: string
    sql: ${TABLE}.request_x_geo_country_code ;;
    group_label: "2. Request Dimensions"
    label: "Country Code"
    description: "Country code from geo headers (x-geo-country-code)"
  }

  dimension: request_x_geo_country_name {
    type: string
    sql: ${TABLE}.request_x_geo_country_name ;;
    group_label: "2. Request Dimensions"
    label: "Country Name"
    description: "Country name from geo headers (x-geo-country-name)"
  }

  dimension: request_x_geo_city {
    type: string
    sql: ${TABLE}.request_x_geo_city ;;
    group_label: "2. Request Dimensions"
    label: "City"
    description: "City from geo headers (x-geo-city)"
  }

  dimension: request_x_geo_isp {
    type: string
    sql: ${TABLE}.request_x_geo_isp ;;
    group_label: "2. Request Dimensions"
    label: "ISP"
    description: "ISP from geo headers (x-geo-isp)"
  }

  dimension: request_x_geo_connection_type {
    type: string
    sql: ${TABLE}.request_x_geo_connection_type ;;
    group_label: "2. Request Dimensions"
    label: "Connection Type"
    description: "Connection type from geo headers (x-geo-connection-type)"
  }

  dimension: request_query {
    type: string
    sql: ${TABLE}.request_query ;;
    group_label: "2. Request Dimensions"
    label: "Query"
    description: "Query parameters from request (JSON array)"
  }

  dimension: request_form {
    type: string
    sql: ${TABLE}.request_form ;;
    group_label: "2. Request Dimensions"
    label: "Form"
    description: "Form data from request (JSON array)"
  }

  dimension: request_json {
    type: string
    sql: ${TABLE}.request_json ;;
    group_label: "2. Request Dimensions"
    label: "JSON"
    description: "JSON body from request (JSON array)"
  }

  # -------------------------
  # 3. Response Meta Dimensions
  # -------------------------

  dimension: response_status {
    type: number
    sql: ${TABLE}.response_status ;;
    group_label: "3. Response Meta Dimensions"
    label: "Status"
    description: "HTTP status code from response"
  }

  dimension: response_content_type {
    type: string
    sql: ${TABLE}.response_content_type ;;
    group_label: "3. Response Meta Dimensions"
    label: "Content Type"
    description: "Content type from response headers"
  }

  dimension: response_x_execution_time {
    type: number
    sql: ${TABLE}.response_x_execution_time ;;
    value_format_name: decimal_4
    group_label: "3. Response Meta Dimensions"
    label: "Execution Time"
    description: "Execution time in seconds from response headers (x-execution-time)"
  }

  dimension: response_x_memory_peak_usage {
    type: string
    sql: ${TABLE}.response_x_memory_peak_usage ;;
    group_label: "3. Response Meta Dimensions"
    label: "Memory Peak Usage"
    description: "Memory peak usage from response headers (x-memory-peak-usage)"
  }

  dimension: response_x_momentum_api_authorization {
    type: string
    sql: ${TABLE}.response_x_momentum_api_authorization ;;
    group_label: "3. Response Meta Dimensions"
    label: "API Authorization"
    description: "API authorization type from response headers (x-momentum-api-authorization)"
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

  # -------------------------
  # 4. Response Data Dimensions
  # -------------------------

  dimension: response_booking_id {
    type: number
    sql: ${TABLE}.response_booking_id ;;
    group_label: "4. Response Data Dimensions"
    label: "Booking ID"
    description: "Booking ID from successful response data"
  }

  # -------------------------
  # 5. Response Error Dimensions
  # -------------------------

  dimension: error_code {
    type: number
    sql: ${TABLE}.error_code ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Code"
    description: "Error code from error response body"
  }

  dimension: error_message {
    type: string
    sql: ${TABLE}.error_message ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Message"
    description: "Error message from error response body"
  }

  dimension: error_details_booking_id {
    type: number
    sql: ${TABLE}.error_details_booking_id ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Details Booking ID"
    description: "Booking ID from error details (if present)"
  }

  dimension: error_details_passenger_id {
    type: number
    sql: ${TABLE}.error_details_passenger_id ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Details Passenger ID"
    description: "Passenger ID from error details (if present)"
  }

  dimension: error_details_work_order_type {
    type: string
    sql: ${TABLE}.error_details_work_order_type ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Details Work Order Type"
    description: "Work order type from error details (if present)"
  }

  dimension: error_details_reason {
    type: string
    sql: ${TABLE}.error_details_reason ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Details Reason"
    description: "Reason from error details (if present)"
  }

  dimension: error_details_error {
    type: string
    sql: ${TABLE}.error_details_error ;;
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

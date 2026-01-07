# Jupiter API Logs Looker Implementation Plan

## Overview
This plan outlines the implementation of a Looker view for the `jupiter.jupiter_api_logs` table using Common Table Expressions (CTEs) to extract and structure JSON data from request and response fields.

## Table Structure
The source table `jupiter.jupiter_api_logs` contains:
- `controller` (String) - Controller name
- `action` (String) - Action name
- `username` (String) - Username
- `http_code` (UInt32) - HTTP status code
- `transaction_group_id` (String) - Transaction group identifier
- `timestamp` (DateTime) - Timestamp of the log entry
- `request` (String) - JSON string containing request data
- `response` (String) - JSON string containing response data

## CTE Structure Pattern
Following the pattern from `wenrix_rq_rs.view.lkml`, we'll use multiple CTEs:

### 1. base_cte
**Purpose**: Create a unique ID and include raw JSON fields for other CTEs to extract from.

**Fields**:
- `id`: Composite key using `toString(timestamp) || '_' || toString(cityHash64(request)) || '_' || toString(cityHash64(response))`
- `controller`: Direct from table
- `action`: Direct from table
- `username`: Direct from table
- `http_code`: Direct from table
- `transaction_group_id`: Direct from table
- `timestamp`: Direct from table
- `request`: Raw JSON string
- `response`: Raw JSON string

### 2. request_cte
**Purpose**: Extract structured data from the request JSON field.

**Fields to extract** (based on `docs/request_example.json`):
- `request_method`: `JSONExtractString(request, 'method')` - HTTP method (GET, POST, etc.)
- `request_host`: `JSONExtractString(request, 'host')` - Host name
- `request_path`: `JSONExtractString(request, 'path')` - API path
- `request_x_request_id`: `JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-request-id')` - Request ID from headers
- `request_user_agent`: `JSONExtractString(JSONExtractRaw(request, 'headers'), 'user-agent')` - User agent
- `request_accept`: `JSONExtractString(JSONExtractRaw(request, 'headers'), 'accept')` - Accept header
- `request_x_geo_country_code`: `JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-geo-country-code')` - Country code
- `request_x_geo_country_name`: `JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-geo-country-name')` - Country name
- `request_x_geo_city`: `JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-geo-city')` - City
- `request_x_geo_isp`: `JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-geo-isp')` - ISP
- `request_x_geo_connection_type`: `JSONExtractString(JSONExtractRaw(request, 'headers'), 'x-geo-connection-type')` - Connection type
- `request_query`: `JSONExtractRaw(request, 'query')` - Query parameters (array)
- `request_form`: `JSONExtractRaw(request, 'form')` - Form data (array)
- `request_json`: `JSONExtractRaw(request, 'json')` - JSON body (array)

### 3. response_meta_cte
**Purpose**: Extract metadata from response JSON (status, headers).

**Fields to extract** (based on response examples):
- `response_status`: `toInt32OrZero(JSONExtractString(response, 'status'))` - HTTP status code from response
- `response_content_type`: `JSONExtractString(JSONExtractRaw(response, 'headers'), 'content-type')` - Content type
- `response_x_execution_time`: `toFloat64OrZero(JSONExtractString(JSONExtractRaw(response, 'headers'), 'x-execution-time'))` - Execution time
- `response_x_memory_peak_usage`: `JSONExtractString(JSONExtractRaw(response, 'headers'), 'x-memory-peak-usage')` - Memory peak usage
- `response_x_momentum_api_authorization`: `JSONExtractString(JSONExtractRaw(response, 'headers'), 'x-momentum-api-authorization')` - Authorization type

**Condition**: `WHERE JSONHas(response, 'status')`

### 4. response_body_data_cte
**Purpose**: Extract data from successful response body (when status is 2xx).

**Fields to extract** (based on `docs/response_success_example.json`):
- `response_body_data`: `JSONExtractRaw(response, 'body')` - Full body JSON
- `response_body_data_array`: `JSONExtractRaw(JSONExtractRaw(response, 'body'), 'data')` - Data array
- `response_booking_id`: Extract first bookingId from data array if available
  - `toInt64OrZero(JSONExtractString(JSONExtractArrayRaw(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'data'), 'data')[1], 'bookingId'))`
- Note: The data structure shows arrays of objects with `bookingId`, `parsed`, and `rules` arrays

**Condition**: `WHERE JSONHas(response, 'body') AND JSONHas(JSONExtractRaw(response, 'body'), 'data')`

### 5. response_body_error_cte
**Purpose**: Extract error information from error response body (when status is 4xx/5xx).

**Fields to extract** (based on `docs/response_failure_example.json`):
- `error_code`: `toInt32OrZero(JSONExtractString(JSONExtractRaw(response, 'body'), 'error_code'))` - Error code
- `error_message`: `JSONExtractString(JSONExtractRaw(response, 'body'), 'error_message')` - Error message
- `error_details_booking_id`: `toInt64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'error_details'), 'bookingId'))` - Booking ID from error details (if present)
- `error_details_passenger_id`: `toInt64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'error_details'), 'passengerId'))` - Passenger ID from error details (if present)
- `error_details_work_order_type`: `JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'error_details'), 'workOrderType')` - Work order type (if present)
- `error_details_reason`: `JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'error_details'), 'reason')` - Reason (if present)
- `error_details_error`: `JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'body'), 'error_details'), 'error')` - Error details (if present)

**Condition**: `WHERE JSONHas(response, 'body') AND JSONHas(JSONExtractRaw(response, 'body'), 'error_code')`

## Final SELECT Statement
Join all CTEs on the `id` field:
```sql
SELECT 
  b.id,
  b.controller,
  b.action,
  b.username,
  b.http_code,
  b.transaction_group_id,
  b.timestamp,
  -- Request fields
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
  -- Response meta fields
  rm.response_status,
  rm.response_content_type,
  rm.response_x_execution_time,
  rm.response_x_memory_peak_usage,
  rm.response_x_momentum_api_authorization,
  -- Response data fields
  rbd.response_booking_id,
  -- Response error fields
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
```

## View Dimensions Organization

### 1. Basic Dimensions
- `id` (hidden, primary_key)
- `controller`
- `action`
- `username`
- `http_code`
- `transaction_group_id`
- `dimension_group: timestamp` (timeframes: raw, date, week, month, quarter, year)

### 2. Request Dimensions
- `request_method`
- `request_host`
- `request_path`
- `request_x_request_id`
- `request_user_agent`
- `request_accept`
- `request_x_geo_country_code`
- `request_x_geo_country_name`
- `request_x_geo_city`
- `request_x_geo_isp`
- `request_x_geo_connection_type`

### 3. Response Meta Dimensions
- `response_status`
- `response_content_type`
- `response_x_execution_time`
- `response_x_memory_peak_usage`
- `response_x_momentum_api_authorization`
- `is_success` (boolean: response_status >= 200 AND response_status < 300)
- `is_error` (boolean: response_status >= 400)

### 4. Response Data Dimensions
- `response_booking_id`

### 5. Response Error Dimensions
- `error_code`
- `error_message`
- `error_details_booking_id`
- `error_details_passenger_id`
- `error_details_work_order_type`
- `error_details_reason`
- `error_details_error`

## Measures

### Basic Counts
- `count` - Total count of log entries
- `count_success` - Count of successful responses (status 2xx)
- `count_error` - Count of error responses (status 4xx/5xx)
- `success_rate` - Percentage of successful responses

### Performance Measures
- `average_execution_time` - Average execution time from response headers
- `total_execution_time` - Sum of execution times
- `max_execution_time` - Maximum execution time
- `min_execution_time` - Minimum execution time

### Distinct Counts
- `distinct_controllers` - Distinct controller names
- `distinct_actions` - Distinct action names
- `distinct_usernames` - Distinct usernames
- `distinct_request_paths` - Distinct API paths
- `distinct_transaction_groups` - Distinct transaction group IDs

### Error Analysis
- `count_by_error_code` - Count grouped by error code
- `count_by_error_message` - Count grouped by error message

## Implementation Steps

1. **Create the view file**: `views/jupiter_api_logs.view.lkml`
2. **Implement base_cte**: Create ID and include all base table columns plus raw JSON
3. **Implement request_cte**: Extract all request JSON fields
4. **Implement response_meta_cte**: Extract response status and headers
5. **Implement response_body_data_cte**: Extract successful response data
6. **Implement response_body_error_cte**: Extract error response data
7. **Create final SELECT**: Join all CTEs together
8. **Add dimensions**: Organize into numbered groups (1-5)
9. **Add measures**: Include counts, rates, and aggregations
10. **Test in Looker**: Validate the explore loads and queries work correctly

## Notes

- Use `JSONExtractString` for string values
- Use `JSONExtractRaw` for nested JSON objects
- Use `toInt32OrZero`, `toInt64OrZero`, `toFloat64OrZero` for numeric conversions
- Use `JSONHas` to check for field existence before extraction
- Handle NULL values appropriately in CASE statements
- Use `parseDateTimeBestEffortOrZero` for timestamp parsing if needed
- Follow the same naming convention: `request_*` for request fields, `response_*` for response fields
- Use `group_label` to organize dimensions into numbered groups
- Mark the `id` dimension as `hidden: yes` and `primary_key: yes`

## Reference Files
- Example CTE pattern: `C:\Users\FilippMozolevskiy\Desktop\Looker\content_integration_cancellation\views\wenrix_rq_rs.view.lkml`
- Table structure: `docs/table_structure.txt`
- Request example: `docs/request_example.json`
- Success response example: `docs/response_success_example.json`
- Failure response example: `docs/response_failure_example.json`


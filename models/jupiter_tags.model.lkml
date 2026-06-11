connection: "clickhouse-jupiter"

include: "/views/**/*.view.lkml"

datagroup: jupiter_tags_default {
  sql_trigger: SELECT toUnixTimestamp(max(timestamp)) FROM jupiter.jupiter_api_tags_v2 ;;
  max_cache_age: "1 hour"
}

persist_with: jupiter_tags_default

# Row grain — one row per label emission. Use for the per-booking trace.
explore: jupiter_tags {
  label: "Jupiter Tags — Event Stream"
  always_filter: {
    filters: [jupiter_tags.timestamp_date: "7 days"]
  }
}

# Transaction grain — one row per HTTP request (transaction_id). Use for N1.
explore: jupiter_tags_transactions {
  label: "Jupiter Tags — Transactions"
  always_filter: {
    filters: [jupiter_tags_transactions.started_date: "7 days"]
  }
}

# Booking grain — one row per booking_id. Use for N2, N3, terminal-state mix.
explore: jupiter_tags_booking_cancels {
  label: "Jupiter Tags — Booking Cancellations"
  always_filter: {
    filters: [jupiter_tags_booking_cancels.first_event_date: "30 days"]
  }
}

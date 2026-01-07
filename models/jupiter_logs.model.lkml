connection: "ota_phoenix"

include: "/views/**/*.view.lkml"


explore: jupiter_logs {
  label: "Content Integration - Jupiter Logs"
  from: jupiter_api_logs
}
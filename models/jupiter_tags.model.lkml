connection: "clickhouse-jupiter"

include: "/views/**/*.view.lkml"


explore: jupiter_tags {
  label: "Jupiter Tags"
  from: jupiter_tags
}

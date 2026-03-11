view: jupiter_tags {

  sql_table_name: jupiter.jupiter_api_tags ;;

  # Required for LookML - update with actual primary key column(s) from table schema
  dimension: id {
    type: string
    sql: toString(${TABLE}.timestamp) ;;
    primary_key: yes
    hidden: yes
  }

}

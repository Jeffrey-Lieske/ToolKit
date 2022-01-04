SELECT "schema",
       "table",
       "size",
       Row_number()
         over (
           ORDER BY "size" DESC)          size_rank,
       tbl_rows,
       "size" / tbl_rows                  density,
       Row_number()
         over (
           ORDER BY "size"/tbl_rows DESC) density_rank
FROM   pg_catalog.svv_table_info sti 
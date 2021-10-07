
  
  select *
  from pg_class where oid = 5429498
  
  --get comment for a specific column
  select col_description(5429498,2)
  
  --get oid for a specific schema.table
  select 'claim_layer.drug'::regclass::oid;
 
 
 select obj_description(6888078,'pg_class') 
 
 /*add comment to a table*/
   comment on table redshift_utilities.profiling is 'This is a test'
  
   
   /*get oid for a table*/
    select 'redshift_utilities.profiling'::regclass::oid;
 
 
 select obj_description(6685055,'pg_class') 
 
 
 --add comment to a column
 comment on column redshift_utilities.profiling.max_len is 'This is the maximum lenght'
 
 --get commnets from each of the columns
   select (select column_name from pg_catalog.svv_all_columns sac where schema_name = 'redshift_utilities'
   	and table_name = 'profiling' and ordinal_position  = 1) column_name,col_description((select 'redshift_utilities.profiling'::regclass::oid),1)
   union ALL
   select (select column_name from pg_catalog.svv_all_columns sac where schema_name = 'redshift_utilities'
   	and table_name = 'profiling' and ordinal_position  = 2) column_name,col_description((select 'redshift_utilities.profiling'::regclass::oid),2)
   union all
   select (select column_name from pg_catalog.svv_all_columns sac where schema_name = 'redshift_utilities'
  	and table_name = 'profiling' and ordinal_position  = 3) column_name,col_description((select 'redshift_utilities.profiling'::regclass::oid),3);
 
--get table, schema, and comment
SELECT cl.relname,obj_description(cl.oid), ns.nspname, cl.oid
FROM pg_class cl
join pg_namespace ns
on cl.relnamespace = ns.oid
WHERE cl.relkind = 'r'
 
 --get all columns and their comments for a table
 select *, col_description (attrelid,attnum)
from pg_attribute
where attrelid = 6685055
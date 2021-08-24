create or replace procedure metadata.profiling(table_name in varchar(400), table_schema in varchar(400))
as $$
declare
sql_query varchar(1000);
get_columns varchar(1000);
column_list record;
list record;


begin
	get_columns := 'select column_name from information_schema.columns where table_name = $q$'||table_name||'$q$ and table_schema = $q$'||table_schema||'$q$';
	execute get_columns into column_list;

		for list in execute get_columns
		loop
			sql_query := 'insert into metadata.profiling(column_name, max_len, min_len) select $q$'||list.column_name||'$q$,max(len('||list.column_name||')),min(len('||list.column_name||')) from '||table_schema||'.'||table_name||';';
			execute sql_query;
    	END LOOP;
  END;
$$ language plpgsql;
SELECT im.table_view, 
       im.object_type, 
       im.index_name, 
       im.index_id, 
       im.index_type, 
       im.columns, 
       im.[unique], 
       s.user_seeks, 
       s.last_user_seek, 
       s.user_scans, 
       s.last_user_scan, 
       s.user_lookups, 
       s.last_user_lookup, 
       s.user_updates, 
       s.last_user_update, 
       s.system_seeks, 
       s.last_system_seek, 
       s.system_scans, 
       s.last_system_scan, 
       s.system_lookups, 
       s.last_system_lookup, 
       s.system_updates, 
       s.last_system_update, 
       sz.indexsizekb 
FROM   (SELECT i.[name]                                          AS index_name, 
               i.index_id, 
               i.object_id, 
               Substring(column_names, 1, Len(column_names) - 1) AS [columns], 
               CASE 
                 WHEN i.[type] = 1 THEN 'Clustered index' 
                 WHEN i.[type] = 2 THEN 'Nonclustered unique index' 
                 WHEN i.[type] = 3 THEN 'XML index' 
                 WHEN i.[type] = 4 THEN 'Spatial index' 
                 WHEN i.[type] = 5 THEN 'Clustered columnstore index' 
                 WHEN i.[type] = 6 THEN 'Nonclustered columnstore index' 
                 WHEN i.[type] = 7 THEN 'Nonclustered hash index' 
               END                                               AS index_type, 
               CASE 
                 WHEN i.is_unique = 1 THEN 'Unique' 
                 ELSE 'Not unique' 
               END                                               AS [unique], 
               Schema_name(t.schema_id) + '.' + t.[name]         AS table_view, 
               CASE 
                 WHEN t.[type] = 'U' THEN 'Table' 
                 WHEN t.[type] = 'V' THEN 'View' 
               END                                               AS 
               [object_type] 
        FROM   sys.objects t 
               INNER JOIN sys.indexes i 
                       ON t.object_id = i.object_id 
               CROSS apply (SELECT col.[name] + ', ' 
                            FROM   sys.index_columns ic 
                                   INNER JOIN sys.columns col 
                                           ON ic.object_id = col.object_id 
                                              AND ic.column_id = col.column_id 
                            WHERE  ic.object_id = t.object_id 
                                   AND ic.index_id = i.index_id 
                            ORDER  BY col.column_id 
                            FOR xml path ('')) D (column_names) 
        WHERE  t.is_ms_shipped <> 1 
               AND index_id > 0 
               AND Objectproperty(I.[object_id], 'IsUserTable') = 1) im 
       LEFT JOIN sys.dm_db_index_usage_stats AS S 
              ON s.index_id = im.index_id 
                 AND s.object_id = im.object_id 
       LEFT JOIN (SELECT index_id, 
                         object_id, 
                         Sum([used_page_count]) * 8 AS IndexSizeKB 
                  FROM   sys.dm_db_partition_stats 
                  GROUP  BY index_id, 
                            object_id) sz 
              ON s.index_id = sz.index_id 
                 AND s.object_id = sz.object_id 
ORDER  BY im.table_view, 
          im.index_id 

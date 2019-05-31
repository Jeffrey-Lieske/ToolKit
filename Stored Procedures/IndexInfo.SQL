CREATE PROCEDURE Sp_indexdetails @loud SMALLINT = 0 
AS 
    DECLARE @db     INT = Db_id(), 
            @sql    NVARCHAR(max) = '', 
            @dbname NVARCHAR(max) 

    IF Object_id('tempdb..#IXDATA') IS NOT NULL 
      DROP TABLE #ixdata 

    CREATE TABLE #ixdata 
      ( 
         [table_view]         [NVARCHAR](257) NULL, 
         [object_type]        [VARCHAR](5) NULL, 
         [index_name]         [SYSNAME] NULL, 
         [index_id]           [INT] NOT NULL, 
         [index_type]         [VARCHAR](30) NULL, 
         [columns]            [NVARCHAR](max) NULL, 
         [unique]             [VARCHAR](10) NOT NULL, 
         [is_primary_key]     [BIT] NOT NULL, 
         [user_seeks]         [BIGINT] NULL, 
         [last_user_seek]     [DATETIME] NULL, 
         [user_scans]         [BIGINT] NULL, 
         [last_user_scan]     [DATETIME] NULL, 
         [user_lookups]       [BIGINT] NULL, 
         [last_user_lookup]   [DATETIME] NULL, 
         [user_updates]       [BIGINT] NULL, 
         [last_user_update]   [DATETIME] NULL, 
         [system_seeks]       [BIGINT] NULL, 
         [last_system_seek]   [DATETIME] NULL, 
         [system_scans]       [BIGINT] NULL, 
         [last_system_scan]   [DATETIME] NULL, 
         [system_lookups]     [BIGINT] NULL, 
         [last_system_lookup] [DATETIME] NULL, 
         [system_updates]     [BIGINT] NULL, 
         [last_system_update] [DATETIME] NULL, 
         [indexsizekb]        [BIGINT] NULL 
      ) 

    CREATE CLUSTERED INDEX [IX_name] 
      ON #ixdata (table_view, index_name) 

    SET @dbname = Db_name(@db) 
    SET @sql = @sql + 'USE [' + @dbname + ']' 

    EXEC (@sql) 

    SET @sql = 'INSERT INTO #ixdata 
SELECT im.table_view, 
       im.object_type, 
       im.index_name, 
       im.index_id, 
       im.index_type, 
       im.columns, 
       im.[unique], 
       im.is_primary_key, 
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
               i.is_primary_key, 
               Substring(column_names, 1, Len(column_names) - 1) AS [columns], 
               CASE 
                 WHEN i.[type] = 1 THEN ''Clustered index'' 
                 WHEN i.[type] = 2 THEN ''Nonclustered unique index'' 
                 WHEN i.[type] = 3 THEN ''XML index'' 
                 WHEN i.[type] = 4 THEN ''Spatial index''
                 WHEN i.[type] = 5 THEN ''Clustered columnstore index'' 
                 WHEN i.[type] = 6 THEN ''Nonclustered columnstore index'' 
                 WHEN i.[type] = 7 THEN ''Nonclustered hash index''
               END                                               AS index_type, 
               CASE 
                 WHEN i.is_unique = 1 THEN ''Unique'' 
                 ELSE ''Not unique'' 
               END                                               AS [unique], 
               Schema_name(t.schema_id) + ''.'' + t.[name]         AS table_view, 
               CASE 
                 WHEN t.[type] = ''U'' THEN ''Table'' 
                 WHEN t.[type] = ''V'' THEN ''View'' 
               END                                               AS 
               [object_type] 
        FROM   sys.objects t 
               INNER JOIN sys.indexes i 
                       ON t.object_id = i.object_id 
               CROSS apply (SELECT col.[name] + '', '' 
                            FROM   sys.index_columns ic 
                                   INNER JOIN sys.columns col 
                                           ON ic.object_id = col.object_id 
                                              AND ic.column_id = col.column_id 
                            WHERE  ic.object_id = t.object_id 
                                   AND ic.index_id = i.index_id 
                            ORDER  BY col.column_id 
                            FOR xml path ('''')) D (column_names) 
        WHERE  t.is_ms_shipped <> 1 
               AND index_id > 0 
               AND Objectproperty(I.[object_id], ''IsUserTable'') = 1) im 
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
                 AND s.object_id = sz.object_id' 

    EXEC (@sql) 

    IF @loud = 0 
      SELECT [table_view], 
             [object_type], 
             [index_name], 
             [index_type], 
             [user_seeks], 
             [indexsizekb], 
             [is_primary_key] 
      FROM   #ixdata 
      ORDER  BY table_view, 
                index_name 

    IF @loud = 1 
      SELECT table_view, 
             object_type, 
             index_name, 
             index_id, 
             index_type, 
             columns, 
             [unique], 
             is_primary_key, 
             user_seeks, 
             last_user_seek, 
             user_scans, 
             last_user_scan, 
             user_lookups, 
             last_user_lookup, 
             user_updates, 
             last_user_update, 
             system_seeks, 
             last_system_seek, 
             system_scans, 
             last_system_scan, 
             system_lookups, 
             last_system_lookup, 
             system_updates, 
             last_system_update, 
             indexsizekb 
      FROM   #ixdata 
      ORDER  BY table_view, 
                index_name;  

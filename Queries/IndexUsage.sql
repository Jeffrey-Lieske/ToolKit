DECLARE @start_time      DATETIME2,
        @stale_time      INT           = 336, --how long (in hours) without being read is considered stale?
        @restart_cut_off INT           = 336, --how long (in hours) after a restart is too soon for data to be considered?
        @command         NVARCHAR(MAX) = N'',
		    @only_low_use	   BIT           = 0
;
SELECT @start_time = sqlserver_start_time
FROM  sys.dm_os_sys_info
;

IF DATEDIFF(HOUR, @start_time, GETDATE()) < @restart_cut_off
      PRINT 'Server restart too recent. Last restart was ' + CAST(@start_time AS VARCHAR(25)) + ' ('
            + CAST(DATEDIFF(HOUR, @start_time, GETDATE()) AS VARCHAR(10)) + ' hours ago, threshhold currently set to '
            + CAST(@restart_cut_off AS VARCHAR(10)) + ')'
      ;
ELSE
      SET @command
            = N'SELECT index_combined.table_name,
       index_combined.index_name,
       index_combined.type_desc,
       index_combined.most_recent_read,
       index_combined.last_user_update,
       index_combined.last_system_update,
       index_combined.index_size_KB
FROM
(
      SELECT index_basics.table_name,
             index_basics.index_name,
             index_basics.type_desc,
             index_basics.is_primary_key,
             (
                   SELECT MAX(v)
                   FROM
                   (
                         VALUES
                               (index_basics.most_recent_user_read),
                               (index_basics.most_recent_system_read)
                   ) AS value(v)
             ) AS most_recent_read,
             index_basics.last_user_update,
             index_basics.last_system_update,
             index_basics.index_size_KB
      FROM
      (
            SELECT OBJECT_NAME(dmius.object_id) table_name,
                   i.name index_name,
                   i.type_desc,
                   i.is_primary_key,
                   (
                         SELECT MAX(v)
                         FROM
                         (
                               VALUES
                                     (dmius.last_user_seek),
                                     (dmius.last_user_scan),
                                     (dmius.last_user_lookup)
                         ) AS value(v)
                   ) AS most_recent_user_read,
                   dmius.last_user_update,
                   (
                         SELECT MAX(v)
                         FROM
                         (
                               VALUES
                                     (dmius.last_system_seek),
                                     (dmius.last_system_scan),
                                     (dmius.last_system_lookup)
                         ) AS value(v)
                   ) AS most_recent_system_read,
                   dmius.last_system_update,
                   SUM(ps.used_page_count) * 8 AS index_size_KB
            FROM  sys.dm_db_index_usage_stats dmius
                  JOIN sys.indexes i
                        ON i.index_id = dmius.index_id
                           AND i.object_id = dmius.object_id
                  JOIN sys.dm_db_partition_stats ps
                        ON ps.index_id = dmius.index_id
                           AND ps.object_id = dmius.object_id
            WHERE dmius.database_id = DB_ID()
            GROUP BY OBJECT_NAME(dmius.object_id),
                     i.name,
                     i.type_desc,
                     i.is_primary_key,
                     dmius.last_user_update,
                     dmius.last_system_update,
                     dmius.last_user_seek,
                     dmius.last_user_scan,
                     dmius.last_user_lookup,
                     dmius.last_system_seek,
                     dmius.last_system_scan,
                     dmius.last_system_lookup
      ) index_basics
      --WHERE index_basics.type_desc <> ''heap'' --heaps are unintersting
) index_combined'

IF @only_low_use = 1
	SET @command = @command +

	' WHERE (index_combined.most_recent_read IS NULL
	      OR DATEDIFF(HOUR, index_combined.most_recent_read, GETDATE()) >=' + CAST(@stale_time AS VARCHAR(10))
	              + N') --show no-read or stale-read indexes
	      AND index_combined.type_desc = ''NONCLUSTERED''
		  '
SET @command = @command + 
' ORDER BY table_name, index_name;'
EXECUTE(@command)
;

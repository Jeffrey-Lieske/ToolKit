DECLARE @SQL varchar(max) = '',
		@tablename varchar(100) = '',
		@schema varchar(50) = '',
		@columnStart int = 0,
		@columnEnd int = 51



SELECT @SQL = @SQL + 'SELECT DISTINCT [' + COLNAME + '] FROM [' + @schema + '].[' + @tablename + '] order by [' + COLNAME + '];
				SELECT MAX(LEN(' + COLNAME + ')) AS ' + COLNAME + '_MAXLEN FROM [' + @schema + '].[' + @tablename + ']'
FROM (
		SELECT c.NAME AS COLNAME FROM sys.columns c
		WHERE OBJECT_NAME(OBJECT_ID) = @tablename and column_id between @columnStart and @columnEnd
		) columns

EXEC (@SQL)
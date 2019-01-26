DECLARE @SQL varchar(max) = '',
		@tablename varchar(100)
SELECT @SQL = @SQL + 'SELECT DISTINCT [' + COLNAME + '] FROM '@tablename +' order by [' + COLNAME + ']; SELECT MAX(LEN(' + COLNAME + ')) AS ' + COLNAME + '_MAXLEN FROM [QCDR5].[dbo].[SID_CA_2011]'
FROM (
		SELECT c.NAME AS COLNAME FROm sys.columns c
		WHERE OBJECT_NAME(OBJECT_ID) = 'SID_CA_2011' and column_id between 0 and 51
		) columns

EXEC (@SQL)


DECLARE @SQL varchar(max) = ''
DECLARE @columns varchar(max) = '(5,6,10)'
select @SQL = @SQL + 'SELECT * from SYS.COLUMNS where COLUMN_ID IN '+@columns + ' and OBJECT_NAME(OBJECT_ID) = ''SID_CA_2011'''
EXEC (@SQL)
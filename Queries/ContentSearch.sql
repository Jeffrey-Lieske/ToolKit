DECLARE @SQL          VARCHAR(max) = '', 
        @tablename    VARCHAR(100) = '', 
        @schema       VARCHAR(50) = '', 
        @columnStart  INT = 0, 
        @columnEnd    INT = 51, 
        @searchString VARCHAR(max) = '' 

IF Object_id('tempDB..#searchResults') IS NOT NULL 
  DROP TABLE #searchresults 

CREATE TABLE #searchresults 
  ( 
     columnname  VARCHAR(1000), 
     stringmatch VARCHAR(1000) 
  ); 

CREATE CLUSTERED INDEX result_ix 
  ON #searchresults (columnname, stringmatch) 

SELECT @SQL = @SQL 
              + 
'INSERT INTO #searchResults(stringMatch,columnName) SELECT DISTINCT [' 
              + colname + '], ''' + colname + ''' FROM [' + @schema + '].[' + @tablename 
              + '] where ' + colname + ' LIKE ''%' 
              + @searchString + '%'';' 
FROM   (SELECT c.NAME AS COLNAME 
        FROM   sys.columns c 
        WHERE  Object_name(object_id) = @tablename 
               AND column_id BETWEEN @columnStart AND @columnEnd) columns 

EXEC (@SQL) 

SELECT * 
FROM   #searchresults 
ORDER  BY columnname, 
          stringmatch 
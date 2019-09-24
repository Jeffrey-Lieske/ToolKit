--import json file from disk
SELECT *
FROM OPENROWSET(BULK 'c:\users\jlieske\documents\catjson.json', SINGLE_NCLOB) AS j

--import and validate json file from disk
DECLARE @jsondata NVARCHAR(MAX) = ''
,@sql nvarchar(MAX)

SELECT @jsondata = bulkcolumn
FROM OPENROWSET(BULK 'c:\users\jlieske\documents\catjson.json', SINGLE_NCLOB) AS j

IF (ISJSON(@jsondata)=1)
	SELECT @jsondata
ELSE
	PRINT 'Invalid JSON'

SELECT *
FROM OPENJSON(@jsondata)

go
--2nd json document load
DECLARE @jsondata NVARCHAR(MAX) = ''
,@sql nvarchar(MAX)

SELECT @jsondata = bulkcolumn
FROM OPENROWSET(BULK 'c:\users\jlieske\documents\jsontest.json', SINGLE_NCLOB) AS j

IF (ISJSON(@jsondata)=1)
	SELECT @jsondata
ELSE
	PRINT 'Invalid JSON'

SELECT *
FROM OPENJSON(@jsondata)


GO
--load reformated cat file
DECLARE @jsondata NVARCHAR(MAX) = ''
,@sql nvarchar(MAX)

SELECT @jsondata = bulkcolumn
FROM OPENROWSET(BULK 'c:\users\jlieske\documents\catjson2.json', SINGLE_NCLOB) AS j

IF (ISJSON(@jsondata)=1)
	SELECT @jsondata
ELSE
	PRINT 'Invalid JSON'

SELECT *
FROM OPENJSON(@jsondata)

--create load table to store raw json
CREATE TABLE cat_json_load
(load_key bigint IDENTITY(1,1),
raw_json VARCHAR(MAX),
 load_time DATETIME DEFAULT GETDATE())
 go
 --load raw json into table (removed "all" header prior to load)
 INSERT INTO cat_json_load(raw_json)
SELECT bulkcolumn
FROM OPENROWSET(BULK 'c:\users\jlieske\documents\catjson2.json', SINGLE_NCLOB) AS  j

go
SELECT *
FROM cat_json_load


CREATE TABLE cat_jason_staging (
staging_key BIGINT IDENTITY(1,1),
load_key BIGINT NOT NULL,
json_key BIGINT NOT NULL,
value VARCHAR(MAX),
type smallint NULL,
load_time DATETIME NOT NULL DEFAULT GETDATE()
)
go
--parse "raw" json for individual rows
DECLARE @load_key BIGINT,
		@json2 NVARCHAR(MAX)
SELECT @load_key = load_key FROM cat_json_load
SELECT @json2 = raw_json FROM cat_json_load
--INSERT INTO cat_jason_staging(load_key,json_key,value, type)
SELECT @load_key, *
FROM OPENJSON(@json2)
go

SELECT *
FROM cat_jason_staging


--parse staging rows
DECLARE @cat_2 VARCHAR(MAX)
SELECT @cat_2 = value FROM cat_jason_staging WHERE json_key = 0

SELECT *
FROM OPENJSON(@cat_2,'$.user')

SELECT JSON_VALUE(@cat_2,'$._id') comment_id,
JSON_VALUE(@cat_2,'$.text') [text],
JSON_VALUE(@cat_2,'$.type') [type],
JSON_VALUE(@cat_2,'$.upvotes') upvotes,
JSON_VALUE(@cat_2,'$.userUpvoted') userUpvoted,
JSON_VALUE(@cat_2,'$.user._id') comment_user_id,
JSON_VALUE(@cat_2,'$.user.name.first') first_name,
JSON_VALUE(@cat_2,'$.user.name.last') last_name

DECLARE @i INT = 0,
		@cat_3 VARCHAR(MAX) = ''

--parse all json staged comments
WHILE @i <= 227
	BEGIN
		SELECT @cat_3 = value FROM cat_jason_staging WHERE json_key = @i

		SELECT	JSON_VALUE(@cat_3,'$._id') comment_id,
				JSON_VALUE(@cat_3,'$.text') [text],
				JSON_VALUE(@cat_3,'$.type') [type],
				JSON_VALUE(@cat_3,'$.upvotes') upvotes,
				JSON_VALUE(@cat_3,'$.userUpvoted') userUpvoted,
				JSON_VALUE(@cat_3,'$.user._id') comment_user_id,
				JSON_VALUE(@cat_3,'$.user.name.first') first_name,
				JSON_VALUE(@cat_3,'$.user.name.last') last_name


		SET @i = @i + 1
	END

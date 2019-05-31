SELECT
	S.name as schemaName
  , O.name AS objectName
  , o.type_desc objectType
  , c.name columnName
  , ep.name extendedPropertyName
  , ep.value extendedPropertyText
  , t.name dataType
  , CASE
		WHEN c.system_type_ID IN (167, 175, 231, 239) AND c.max_length = -1 THEN 'MAX'
		WHEN c.user_type_id IN (167, 175) AND c.max_length <> -1 THEN CAST(c.max_length AS VARCHAR)
		WHEN c.user_type_id IN (231, 239) AND c.max_length <> -1 THEN CAST(c.max_length/2 AS VARCHAR)
		ELSE NULL
	END [maxLength]
  , CASE
		WHEN c.system_type_id IN (108) THEN c.precision
	ELSE NULL
	END [precision],
	CASE
		WHEN c.system_type_id IN (108) THEN c.scale
	ELSE NULL
	END scale
  , c.is_nullable
FROM
	sys.extended_properties EP
	RIGHT JOIN
		sys.all_objects O
		ON
			ep.major_id = O.object_id
	LEFT JOIN
		sys.schemas S
		on
			O.schema_id = S.schema_id
	LEFT JOIN
		sys.columns c
		ON
			ep.major_id     = c.object_id
			AND ep.minor_id = c.column_id
	LEFT JOIN 
		sys.types T
		ON c.system_type_id = t.user_type_id
WHERE o.is_ms_shipped <> 1 --ignore internal objects
AND o.type IN ('V','U') --pull only views and user tables
ORDER BY schemaName, objectName, columnName

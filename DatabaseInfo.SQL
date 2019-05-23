SELECT db.name,db.compatibility_level,db.state,
  db.is_read_only,db.recovery_model_desc,db.page_verify_option_desc, lg.name db_owner
FROM sys.databases db
LEFT JOIN sys.syslogins lg
  ON db.owner_sid = lg.sid
WHERE db.database_id NOT IN (1,2,3,4)

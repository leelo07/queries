SELECT DB_NAME(7),OBJECT_NAME(1454628225)
FROM sys.dm_db_index_usage_stats
WHERE user_seeks = 0
AND user_scans = 0
AND user_lookups = 0
AND system_seeks = 0
AND system_scans = 0
AND system_lookups = 0
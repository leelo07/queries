SELECT OBJECT_NAME(i.OBJECT_ID) AS TableName,
i.name AS IndexName,
indexstats.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') indexstats
INNER JOIN sys.indexes i ON i.OBJECT_ID = indexstats.OBJECT_ID
AND i.index_id = indexstats.index_id
WHERE indexstats.avg_fragmentation_in_percent > 20


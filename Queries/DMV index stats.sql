SELECT *
FROM sys.dm_db_index_physical_stats (DB_ID('LFMBSI')
,OBJECT_ID('dbo.AuditEvent')
,NULL 
-- NULL to view all indexes; 
-- otherwise, input index number
,NULL -- NULL to view all partitions of an index
,'DETAILED') -- We want all information
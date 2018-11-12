-- FRAGMENTATION > 10 Percent ?  LINE 23
--use VCDB;
declare @dbid char(50)
SELECT 
                DB_NAME(s.database_id) DBName,
                o.NAME TblName,
                i.NAME IX_Name,
                s.index_type_desc,
                s.avg_fragmentation_in_percent,
                s.avg_fragment_size_in_pages,
                s.page_count,
                s.fragment_count,
                i.fill_factor,
                s.partition_number,
                s.alloc_unit_type_desc
--INTO TableFragmentation
FROM sys.dm_db_index_physical_stats(@DBID,NULL, NULL, NULL, 'LIMITED') s
JOIN sys.objects o
  on o.object_id = s.object_id
JOIN sys.indexes i 
  on o.object_id = i.Object_id
  and s.index_id = i.index_id
WHERE
  o.type_desc = 'USER_TABLE' 
  AND avg_fragmentation_in_percent > 10
  AND i.Name is not NULL
ORDER BY s.page_count DESC

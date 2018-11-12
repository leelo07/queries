--output may exceed width of editor
select cast( 'use ['+DB_NAME()+']' as varchar(500)) 
union all 
SELECT 'GO' 
union all 
SELECT 
'select DB_NAME() as DB, '''+OBJECT_NAME(c.OBJECT_ID)+''' as TableName, '''+c.name+''' as ColumnName, '''+t.name+ ''' as SS_TYPE, max(datalength(['+OBJECT_NAME(c.OBJECT_ID)+'].['+c.name+'])) as Max_DataLength from ['+SCHEMA_NAME(o.schema_id)+'].['+OBJECT_NAME(c.OBJECT_ID)+'] union all' 
FROM sys.columns AS c 
JOIN sys.types AS t ON c.user_type_id=t.user_type_id 
join sys.objects as o on c.object_id = o.object_id 
WHERE 
o.type = 'U' 
and 
(t.name like '%text%' 
OR 
(t.name like '%varchar%' and c.max_length = -1) 
OR 
(t.name like '%binary%') 
) 
and OBJECT_NAME(c.OBJECT_ID) not like 'syncobj%' 
and OBJECT_NAME(c.OBJECT_ID) not like 'sys%' -- PLANDATA.dbo.systemset is the only Molina table 
-- that matches this pattern and does not have any BLOBS 
--ORDER BY OBJECT_NAME(c.OBJECT_ID), c.OBJECT_ID; 



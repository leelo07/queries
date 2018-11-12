--use AW2012
select top 10 [Table]=name, Rows
from sys.tables t
inner join sys.partitions p
on t.object_id = p.object_id
and p.index_id < 2
order by 2 desc

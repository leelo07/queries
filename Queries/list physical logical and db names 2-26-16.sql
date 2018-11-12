select d.name as db_name, m.name as logical_name, m.physical_name
 from sys.master_files m 
 inner join sys.databases d 
 on (m.database_id = d.database_id) 
 order by 1, 2
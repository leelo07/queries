--SELECT name, database_id, is_trustworthy_on FROM sys.databases 
SELECT database_id, mirroring_role, mirroring_safety_level_desc, mirroring_state_desc FROM sys.database_mirroring
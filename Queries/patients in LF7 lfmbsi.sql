 --select count(*) from (select distinct company, time, region from test) t
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO
BEGIN TRANSACTION;
GO
SELECT COUNT (*) 
FROM (SELECT DISTINCT data_set,family_number FROM [LFMBSI].[dbo].[TD11]) t  
GO
COMMIT TRANSACTION;
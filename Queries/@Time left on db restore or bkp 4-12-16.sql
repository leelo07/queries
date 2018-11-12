USE master
 GO

SELECT
    Percent_Complete,
    Start_Time ,
    Command, 
    b.Name AS DatabaseName, --Sometimes this will be "master" as the database will not be accesiable.
    DATEADD(ms,estimated_completion_time,GETDATE()) AS EstimatedFinishTime,
    (estimated_completion_time/1000/60) AS MinutesToFinish
FROM sys.dm_exec_requests a
    INNER JOIN sys.databases b 
    ON a.database_id = b.database_id
WHERE
    Command like '%Restore%'
    OR Command like '%Backup%'
    AND Estimated_Completion_Time > 0 
--Returns the buffer cache hit ratio
SELECT ROUND(CAST (A.cntr_value1 AS NUMERIC) / CAST (B.cntr_value2 AS NUMERIC), 3) AS Buffer_Cache_Hit_Ratio
FROM(SELECT cntr_value AS cntr_value1
	FROM sys.dm_os_performance_counters
	WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Buffer cache hit ratio') 
AS A,(SELECT cntr_value AS cntr_value2
	FROM sys.dm_os_performance_counters
	WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Buffer cache hit ratio base') AS B 
--Returns the page life expectancy in minutes
SELECT round ( (CAST (cntr_value AS NUMERIC) / 60), 1) AS 'Page Life Expectancy in Minutes'
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Page life expectancy' 
--Returns pages read per second
SELECT cntr_value AS 'Page reads per Second'FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Page reads/sec' 
--Returns pages written per second
SELECT cntr_value AS 'Page writes per Second'FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Page writes/sec' 
--Returns Free list Stall per second
SELECT cntr_value AS 'Free List Stalls per second'FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Free list stalls/sec' 
--Returns Lazy writes per second
SELECT cntr_value AS 'Lazy writes per second'
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Lazy writes/sec' 
--Returns Total SQL Server Memory
SELECT cntr_value AS 'Total SQL Server Memory'
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Memory Manager' and counter_name = 'Total Server Memory (KB)' 
--Average Latch Wait Time
SELECT ROUND(CAST (A.cntr_value1 AS NUMERIC) / CAST (B.cntr_value2 AS NUMERIC), 3) AS [Average Latch Wait Time]
FROM(SELECT cntr_value AS cntr_value1FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Latches' and counter_name = 'Average Latch Wait Time (ms)' ) AS A,(SELECT cntr_value 
AS cntr_value2FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Latches' AND counter_name = 
'Average Latch Wait Time Base') AS B 
-- Returns Pending memory grants
SELECT cntr_value AS 'Pending memory grants'
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Resource Pool Stats'and counter_name = 'Pending memory grants count' 
-- Returns Pending Disk IO Count
SELECT [pending_disk_io_count] AS [Pending Disk IO Count] FROM sys.dm_os_schedulers 
-- Returns the number of user connections
SELECT cntr_value AS [User Connections] FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:General Statistics' and counter_name = 'User Connections' 
--Returns CPU Utilization Percentage
SELECT(ROUND(CAST (A.cntr_value1 AS NUMERIC) / CAST (B.cntr_value2 AS NUMERIC), 3))*100 
AS [CPU Utilization Percentage]
FROM(SELECT cntr_value AS cntr_value1
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Resource Pool Stats' and counter_name = 'CPU usage %' ) AS A,(SELECT cntr_value AS cntr_value2
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Resource Pool Stats' and counter_name = 'CPU usage % base' ) AS B 
--Returns Data File Size
SELECT instance_name AS 'DB Name',cntr_value AS 'Data File Size'
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Databases' and counter_name = 'Data File(s) Size (KB)' 
--Remaining Log File KB 
SELECT A.instance_name as 'DB',CAST (Size AS NUMERIC) - CAST (Used AS NUMERIC) AS [Available Log File KB]
From(SELECT instance_name ,cntr_value AS Size
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Databases'
and counter_name = 'Log File(s) Size (KB)') 
AS Ainner join (SELECT instance_name ,cntr_value AS UsedFROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Databases'
and counter_name = 'Log File(s) Used Size (KB)') AS Bon A.instance_name = B.instance_name 
-- Returns percent Log File Used
SELECT instance_name as 'DB', cntr_value as 'Percent Log Used'
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Percent Log Used' 
--Returns Transactions per second
SELECT * --instance_name AS 'DB Name', cntr_value AS 'Transactions per second'
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Databases' and counter_name = 'Transactions/sec'
-- SQL Server 2008 and R2 Diagnostic Information Queries
-- Glenn Berry 
-- September 2010
-- http://glennberrysqlperformance.spaces.live.com/
-- Twitter: GlennAlanBerry 

-- Instance level queries ******************************* 

-- SQL and OS Version information for current instance
SELECT @@VERSION AS [SQL Server and OS Version Info]; 

-- SQL Server 2008 RTM is considered an "unsupported service pack" 
-- as of April 13, 2010
-- SQL Server 2008 RTM Builds     SQL Server 2008 SP1 Builds     SQL Server 2008 SP2 Builds
-- Build       Description        Build        Description         Build     Description
-- 1600        Gold RTM
-- 1763        RTM CU1
-- 1779        RTM CU2
-- 1787        RTM CU3    -->      2531        SP1 RTM
-- 1798        RTM CU4    -->      2710        SP1 CU1
-- 1806        RTM CU5    -->      2714        SP1 CU2 
-- 1812        RTM CU6    -->      2723        SP1 CU3
-- 1818        RTM CU7    -->      2734        SP1 CU4
-- 1823        RTM CU8    -->      2746        SP1 CU5
-- 1828        RTM CU9    -->      2757        SP1 CU6
-- 1835        RTM CU10   -->     2766        SP1 CU7
-- RTM Branch Retired     -->     2775        SP1 CU8      -->  3798       SP2 CTP
--                                            2789         SP1 CU9                                   

-- SQL Azure Builds (most DMV queries don't work on SQL Azure)
-- Build            Description
-- 10.25.9200       RTM Service Update 1
-- 10.25.9268       RTM Service Update 2
-- 10.25.9331       RTM Service Update 3
-- 10.25.9386       RTM Service Update 4 

-- SQL Server 2008 R2 Builds
-- Build            Description
-- 10.50.1092        August 2009 CTP2
-- 10.50.1352        November 2009 CTP3
-- 10.50.1450        Release Candidate
-- 10.50.1600        RTM
-- 10.50.1702        RTM CU1
-- 10.50.1720        RTM CU2
-- 10.50.1734        RTM CU3 

-- Hardware information from SQL Server 2008 
-- (Cannot distinguish between HT and multi-core)
SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],
cpu_count/hyperthread_ratio AS [Physical CPU Count], 
physical_memory_in_bytes/1048576 AS [Physical Memory (MB)], sqlserver_start_time
FROM sys.dm_os_sys_info; 

-- Get configuration values for instance
SELECT name, value, value_in_use, [description] 
FROM sys.configurations
ORDER BY name ; 

-- Focus on
-- backup compression default
-- clr enabled (only enable if it is needed)
-- lightweight pooling (should be zero)
-- max degree of parallelism 
-- max server memory (MB) (set to an appropriate value)
-- optimize for ad hoc workloads (should be 1)
-- priority boost (should be zero) 

-- File Names and Paths for TempDB and all user databases in instance 
SELECT DB_NAME([database_id])AS [Database Name], 
       [file_id], name, physical_name, type_desc, state_desc, size
FROM sys.master_files
WHERE [database_id] > 4 
AND [database_id] <> 32767
OR [database_id] = 2; 

-- Things to look at:
-- Are data files and log files on different drives?
-- Is everything on the C: drive?
-- Is TempDB on dedicated drives?
-- Are there multiple data files? 

-- Calculates average stalls per read, per write, and per total input/output for each database file. 
SELECT DB_NAME(fs.database_id) AS [Database Name], mf.physical_name, io_stall_read_ms, num_of_reads,
CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],io_stall_write_ms, 
num_of_writes,CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],
io_stall_read_ms + io_stall_write_ms AS [io_stalls], num_of_reads + num_of_writes AS [total_io],
CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) 
AS [avg_io_stall_ms]
FROM sys.dm_io_virtual_file_stats(null,null) AS fs
INNER JOIN sys.master_files AS mf
ON fs.database_id = mf.database_id
AND fs.[file_id] = mf.[file_id]
ORDER BY avg_io_stall_ms DESC; 

-- Helps determine which database files on the entire instance have the most I/O bottlenecks 

-- Recovery model, log reuse wait description, log file size, log usage size 
-- and compatibility level for all databases on instance
SELECT db.[name] AS [Database Name], db.recovery_model_desc AS [Recovery Model], 
db.log_reuse_wait_desc AS [Log Reuse Wait Description], 
ls.cntr_value AS [Log Size (KB)], lu.cntr_value AS [Log Used (KB)],
CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS [Log Used %], 
db.[compatibility_level] AS [DB Compatibility Level], 
db.page_verify_option_desc AS [Page Verify Option], db.is_auto_update_stats_on,
db.is_auto_update_stats_async_on, db.is_parameterization_forced, db.is_supplemental_logging_enabled, 
db.snapshot_isolation_state_desc, db.is_read_committed_snapshot_on
FROM sys.databases AS db
INNER JOIN sys.dm_os_performance_counters AS lu 
ON db.name = lu.instance_name
INNER JOIN sys.dm_os_performance_counters AS ls 
ON db.name = ls.instance_name
WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%' 
AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
AND ls.cntr_value > 0; 

-- Things to look at:
-- How many databases are on the instance?
-- What recovery models are they using?
-- What is the log reuse wait description?
-- How full are the transaction logs ?
-- What compatibility level are they on? 

-- Clear Wait Stats 
-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR); 

-- Isolate top waits for server instance since last restart or statistics clear
WITH Waits AS
(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s,
100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE'
,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_MANUAL_EVENT'
,'CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT'
,'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'))
SELECT W1.wait_type, 
CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 99; -- percentage threshold 

-- Common Significant Wait types with BOL explanations 

-- *** Network Related Waits ***
-- ASYNC_NETWORK_IO        Occurs on network writes when the task is blocked behind the network 

-- *** Locking Waits ***
-- LCK_M_IX                Occurs when a task is waiting to acquire an Intent Exclusive (IX) lock
-- LCK_M_IU                Occurs when a task is waiting to acquire an Intent Update (IU) lock
-- LCK_M_S                Occurs when a task is waiting to acquire a Shared lock 

-- *** I/O Related Waits ***
-- ASYNC_IO_COMPLETION  Occurs when a task is waiting for I/Os to finish
-- IO_COMPLETION        Occurs while waiting for I/O operations to complete. 
--                      This wait type generally represents non-data page I/Os. Data page I/O completion waits appear 
--                      as PAGEIOLATCH_* waits
-- PAGEIOLATCH_SH        Occurs when a task is waiting on a latch for a buffer that is in an I/O request. 
--                      The latch request is in Shared mode. Long waits may indicate problems with the disk subsystem.
-- PAGEIOLATCH_EX        Occurs when a task is waiting on a latch for a buffer that is in an I/O request. 
--                      The latch request is in Exclusive mode. Long waits may indicate problems with the disk subsystem.
-- WRITELOG             Occurs while waiting for a log flush to complete. 
--                      Common operations that cause log flushes are checkpoints and transaction commits.
-- PAGELATCH_EX            Occurs when a task is waiting on a latch for a buffer that is not in an I/O request. 
--                      The latch request is in Exclusive mode.
-- BACKUPIO                Occurs when a backup task is waiting for data, or is waiting for a buffer in which to store data 

-- *** CPU Related Waits ***
-- SOS_SCHEDULER_YIELD  Occurs when a task voluntarily yields the scheduler for other tasks to execute. 
--                      During this wait the task is waiting for its quantum to be renewed. 

-- THREADPOOL            Occurs when a task is waiting for a worker to run on. 
--                      This can indicate that the maximum worker setting is too low, or that batch executions are taking 
--                      unusually long, thus reducing the number of workers available to satisfy other batches.
-- CX_PACKET            Occurs when trying to synchronize the query processor exchange iterator 
--                        You may consider lowering the degree of parallelism if contention on this wait type becomes a problem 

-- Signal Waits for instance
SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) 
AS [%signal (cpu) waits],
CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) 
AS [%resource waits]
FROM sys.dm_os_wait_stats; 

-- Signal Waits above 10-15% is usually a sign of CPU pressure 

-- Get CPU Utilization History for last 144 minutes (in one minute intervals)
-- This version works with SQL Server 2008 and SQL Server 2008 R2 only
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 

SELECT TOP(144) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM ( 
      SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
            AS [SystemIdle], 
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
            'int') 
            AS [SQLProcessUtilization], [timestamp] 
      FROM ( 
            SELECT [timestamp], CONVERT(xml, record) AS [record] 
            FROM sys.dm_os_ring_buffers 
            WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
            AND record LIKE N'%<SystemHealth>%') AS x 
      ) AS y 
ORDER BY record_id DESC; 

-- Good basic information about memory amounts and state
SELECT total_physical_memory_kb, available_physical_memory_kb, 
       total_page_file_kb, available_page_file_kb, 
       system_memory_state_desc
FROM sys.dm_os_sys_memory; 

-- You want to see "Available physical memory is high" 

-- SQL Server Process Address space info 
--(shows whether locked pages is enabled, among other things)
SELECT physical_memory_in_use_kb,locked_page_allocations_kb, 
       page_fault_count, memory_utilization_percentage, 
       available_commit_limit_kb, process_physical_memory_low, 
       process_virtual_memory_low
FROM sys.dm_os_process_memory; 

-- You want to see 0 for process_physical_memory_low
-- You want to see 0 for process_virtual_memory_low 

-- Page Life Expectancy (PLE) value for default instance
SELECT cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters
WHERE OBJECT_NAME = N'SQLServer:Buffer Manager' -- Modify this if you have named instances
AND counter_name = N'Page life expectancy'; 

-- PLE is a good measurement of memory pressure.
-- Higher PLE is better. Below 300 is generally bad.
-- Watch the trend, not the absolute value. 

-- Buffer cache hit ratio for default instance
SELECT (a.cntr_value * 1.0 / b.cntr_value) * 100.0 AS [Buffer Cache Hit Ratio]
FROM sys.dm_os_performance_counters AS a
INNER JOIN (SELECT cntr_value, [OBJECT_NAME]
            FROM sys.dm_os_performance_counters  
            WHERE counter_name = N'Buffer cache hit ratio base'
            AND [OBJECT_NAME] = N'SQLServer:Buffer Manager') AS b -- Modify this if you have named instances
ON a.[OBJECT_NAME] = b.[OBJECT_NAME]
WHERE a.counter_name = N'Buffer cache hit ratio'
AND a.[OBJECT_NAME] = N'SQLServer:Buffer Manager'; -- Modify this if you have named instances 

-- Shows the percentage that SQL Server is finding requested data in memory
-- A higher percentage is better than a lower percentage
-- Watch the trend, not the absolute value. 

-- Memory Clerk Usage for instance
-- Look for high value for CACHESTORE_SQLCP (Ad-hoc query plans)
SELECT TOP(20) [type], [name], SUM(single_pages_kb) AS [SPA Mem, Kb] 
FROM sys.dm_os_memory_clerks 
GROUP BY [type], [name]  
ORDER BY SUM(single_pages_kb) DESC; 

-- CACHESTORE_SQLCP  SQL Plans         These are cached SQL statements or batches that aren't in 
--                                     stored procedures, functions and triggers
-- CACHESTORE_OBJCP  Object Plans      These are compiled plans for stored procedures, 
--                                     functions and triggers
-- CACHESTORE_PHDR   Algebrizer Trees  An algebrizer tree is the parsed SQL text that 
--                                     resolves the table and column names 

-- Find single-use, ad-hoc queries that are bloating the plan cache
SELECT TOP(100) [text], cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE cp.cacheobjtype = N'Compiled Plan' 
AND cp.objtype = N'Adhoc' 
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC; 

-- Gives you the text and size of single-use ad-hoc queries that waste space in the plan cache
-- Enabling 'optimize for ad hoc workloads' for the instance can help (SQL Server 2008 and 2008 R2 only)
-- Enabling forced parameterization for the database can help, but test first! 

-- Database specific queries ***************************************************************** 

-- **** Switch to a user database *****
USE YourDatabaseName;
GO 

-- Individual File Sizes and space available for current database
SELECT name AS [File Name] , physical_name AS [Physical Name], size/128.0 AS [Total Size in MB],
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS [Available Space In MB], [file_id]
FROM sys.database_files; 

-- Look at how large and how full the files are and where they are located
-- Make sure the transaction log is not full!! 

-- Top Cached SPs By Execution Count (SQL 2008)
SELECT TOP(25) p.name AS [SP Name], qs.execution_count,
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], qs.total_worker_time AS [TotalWorkerTime],  
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.execution_count DESC; 

-- Tells you which cached stored procedures are called the most often
-- This helps you characterize and baseline your workload 

-- Top Cached SPs By Avg Elapsed Time (SQL 2008)
SELECT TOP(25) p.name AS [SP Name], qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], 
qs.total_elapsed_time, qs.execution_count, ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, 
GETDATE()), 0) AS [Calls/Second], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.total_worker_time AS [TotalWorkerTime], qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY avg_elapsed_time DESC; 

-- This helps you find long-running cached stored procedures 

-- Top Cached SPs By Total Worker time (SQL 2008). Worker time relates to CPU cost
SELECT TOP(25) p.name AS [SP Name], qs.total_worker_time AS [TotalWorkerTime], 
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], qs.execution_count, 
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count 
AS [avg_elapsed_time], qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_worker_time DESC; 

-- This helps you find the most expensive cached stored procedures from a CPU perspective
-- You should look at this if you see signs of CPU pressure 

-- Top Cached SPs By Total Logical Reads (SQL 2008). Logical reads relate to memory pressure
SELECT TOP(25) p.name AS [SP Name], qs.total_logical_reads AS [TotalLogicalReads], 
qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],qs.execution_count, 
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second], 
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count 
AS [avg_elapsed_time], qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_logical_reads DESC; 

-- This helps you find the most expensive cached stored procedures from a memory perspective
-- You should look at this if you see signs of memory pressure 

-- Top Cached SPs By Total Physical Reads (SQL 2008). Physical reads relate to disk I/O pressure
SELECT TOP(25) p.name AS [SP Name],qs.total_physical_reads AS [TotalPhysicalReads], 
qs.total_physical_reads/qs.execution_count AS [AvgPhysicalReads], qs.execution_count, 
qs.total_logical_reads,qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count 
AS [avg_elapsed_time], qs.cached_time 
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_physical_reads, qs.total_logical_reads DESC; 

-- This helps you find the most expensive cached stored procedures from a read I/O perspective
-- You should look at this if you see signs of I/O pressure or of memory pressure
-- Top Cached SPs By Total Logical Writes (SQL 2008). 
-- Logical writes relate to both memory and disk I/O pressure 
SELECT TOP(25) p.name AS [SP Name], qs.total_logical_writes AS [TotalLogicalWrites], 
qs.total_logical_writes/qs.execution_count AS [AvgLogicalWrites], qs.execution_count,
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], 
qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_logical_writes DESC; 

-- This helps you find the most expensive cached stored procedures from a write I/O perspective
-- You should look at this if you see signs of I/O pressure or of memory pressure 

-- Lists the top statements by average input/output usage for the current database
SELECT TOP(50) OBJECT_NAME(qt.objectid) AS [SP Name],
(qs.total_logical_reads + qs.total_logical_writes) /qs.execution_count AS [Avg IO],
SUBSTRING(qt.[text],qs.statement_start_offset/2, 
    (CASE 
        WHEN qs.statement_end_offset = -1 
     THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 
        ELSE qs.statement_end_offset 
     END - qs.statement_start_offset)/2) AS [Query Text]    
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.[dbid] = DB_ID()
ORDER BY [Avg IO] DESC; 

-- Helps you find the most expensive statements for I/O by SP 

-- Possible Bad NC Indexes (writes > reads)
SELECT OBJECT_NAME(s.[object_id]) AS [Table Name], i.name AS [Index Name], i.index_id,
user_updates AS [Total Writes], user_seeks + user_scans + user_lookups AS [Total Reads],
user_updates - (user_seeks + user_scans + user_lookups) AS [Difference]
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON s.[object_id] = i.[object_id]
AND i.index_id = s.index_id
WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND s.database_id = DB_ID()
AND user_updates > (user_seeks + user_scans + user_lookups)
AND i.index_id > 1
ORDER BY [Difference] DESC, [Total Writes] DESC, [Total Reads] ASC; 

-- Look for indexes with high numbers of writes and zero or very low numbers of reads
-- Consider your complete workload
-- Investigate further before dropping an index 

-- Missing Indexes current database by Index Advantage
SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS [index_advantage], 
migs.last_user_seek, mid.[statement] AS [Database.Schema.Table],
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID() -- Remove this to see for entire instance
ORDER BY index_advantage DESC; 

-- Look at last user seek time, number of user seeks to help determine source and importance
-- SQL Server is overly eager to add included columns, so beware
-- Do not just blindly add indexes that show up from this query!!! 

-- Breaks down buffers used by current database by object (table, index) in the buffer cache
SELECT OBJECT_NAME(p.[object_id]) AS [ObjectName], 
p.index_id, COUNT(*)/128 AS [Buffer size(MB)],  COUNT(*) AS [BufferCount], 
p.data_compression_desc AS [CompressionType]
FROM sys.allocation_units AS a
INNER JOIN sys.dm_os_buffer_descriptors AS b
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p
ON a.container_id = p.hobt_id
WHERE b.database_id = DB_ID()
AND p.[object_id] > 100
GROUP BY p.[object_id], p.index_id, p.data_compression_desc
ORDER BY [BufferCount] DESC; 

-- Tells you what tables and indexes are using the most memory in the buffer cache 

-- Get Table names, row counts, and compression status for clustered index or heap
SELECT OBJECT_NAME(object_id) AS [ObjectName], 
SUM(Rows) AS [RowCount], data_compression_desc AS [CompressionType]
FROM sys.partitions 
WHERE index_id < 2 --ignore the partitions from the non-clustered index if any
AND OBJECT_NAME(object_id) NOT LIKE 'sys%'
AND OBJECT_NAME(object_id) NOT LIKE 'queue_%' 
AND OBJECT_NAME(object_id) NOT LIKE 'filestream_tombstone%' 
GROUP BY object_id, data_compression_desc
ORDER BY SUM(Rows) DESC; 

-- Gives you an idea of table sizes, and possible data compression opportunities 

-- When were Statistics last updated on all indexes?
SELECT o.name, i.name AS [Index Name],  
      STATS_DATE(i.[object_id], i.index_id) AS [Statistics Date], 
      s.auto_created, s.no_recompute, s.user_created, st.row_count
FROM sys.objects AS o WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON o.[object_id] = i.[object_id]
INNER JOIN sys.stats AS s WITH (NOLOCK)
ON i.[object_id] = s.[object_id] 
AND i.index_id = s.stats_id
INNER JOIN sys.dm_db_partition_stats AS st WITH (NOLOCK)
ON o.[object_id] = st.[object_id]
WHERE o.[type] = 'U'
ORDER BY STATS_DATE(i.[object_id], i.index_id) ASC;    

-- Helps discover possible problems with out-of-date statistics
-- Also gives you an idea which indexes are most active

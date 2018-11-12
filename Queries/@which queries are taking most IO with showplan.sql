-- Which queries are causing the most IO operations (can take a few seconds)
SELECT TOP (20) total_logical_reads/execution_count AS [avg_logical_reads],
    total_logical_writes/execution_count AS [avg_logical_writes],
    total_worker_time/execution_count AS [avg_cpu_cost], execution_count,
    total_worker_time, total_logical_reads, total_logical_writes,
    (SELECT DB_NAME(dbid) + ISNULL('..' + OBJECT_NAME(objectid), '')
     FROM sys.dm_exec_sql_text([sql_handle])) AS query_database,
    (SELECT SUBSTRING(est.[text], statement_start_offset/2 + 1,
        (CASE WHEN statement_end_offset = -1
            THEN LEN(CONVERT(nvarchar(max), est.[text])) * 2
            ELSE statement_end_offset
            END - statement_start_offset
        ) / 2)
        FROM sys.dm_exec_sql_text(sql_handle) AS est) AS query_text,
    last_logical_reads, min_logical_reads, max_logical_reads,
    last_logical_writes, min_logical_writes, max_logical_writes,
    total_physical_reads, last_physical_reads, min_physical_reads, max_physical_reads,
    (total_logical_reads + (total_logical_writes * 5))/execution_count AS io_weighting,
    plan_generation_num, qp.query_plan
FROM sys.dm_exec_query_stats
OUTER APPLY sys.dm_exec_query_plan([plan_handle]) AS qp
WHERE [dbid] >= 5 AND (total_worker_time/execution_count) > 100
ORDER BY io_weighting DESC;

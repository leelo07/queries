SELECT *
FROM sys.dm_exec_query_memory_grants
WHERE is_next_candidate in (0,1)
ORDER BY is_next_candidate desc, queue_id, wait_order;

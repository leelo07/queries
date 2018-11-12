SELECT cpu_count AS 'Logical CPU Count', hyperthread_ratio AS 'Hyperthread Ratio',
cpu_count/hyperthread_ratio As 'Physical CPU Count'
--,physical_memory_in_bytes/1048576 AS 'Physical Memory (MB)'
FROM sys.dm_os_sys_info
order by 1

select case
 
         when cpu_count / hyperthread_ratio > 8 then 8
 
         else cpu_count / hyperthread_ratio
 
       end as optimal_maxdop_setting
 
from sys.dm_os_sys_info;
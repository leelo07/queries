select  
    scheduler_id, 
    current_tasks_count, 
    runnable_tasks_count 
from  
    sys.dm_os_schedulers 
where  
    scheduler_id < 255

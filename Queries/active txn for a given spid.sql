-- ********************************************************************** 
-- * This query will show the SQL for the SPID entered on the last line *
-- **********************************************************************
SELECT host_name,program_name, original_login_name, st.text
   FROM sys.dm_exec_sessions es
      INNER JOIN sys.dm_exec_connections ec
          ON es.session_id = ec.session_id
      CROSS APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) st
   WHERE ec.session_id = 172 --<== This is the SPID for which you want the SQL text
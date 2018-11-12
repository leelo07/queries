SELECT DB_NAME(dbid)AS DBName,
       COUNT(dbid)   AS NumberOfConnections,
       loginame      AS LoginName,
       nt_domain     AS NT_Domain,
       nt_username   AS NT_UserName,
       hostname      AS HostName
FROM   sys.sysprocesses
WHERE  dbid > 0  and DB_NAME(dbid) = 'VordelAAA'
GROUP  BY dbid,
          hostname,
          loginame,
          nt_domain,
          nt_username
ORDER  BY NumberOfConnections DESC;
SELECT DB_NAME(dbid)AS DBName,
       COUNT(dbid)   AS NumberOfConnections,
       loginame      AS LoginName,
       nt_domain     AS NT_Domain,
       nt_username   AS NT_UserName,
       hostname      AS HostName
FROM   sys.sysprocesses
WHERE  dbid > 0 
GROUP  BY dbid,
          hostname,
          loginame,
          nt_domain,
          nt_username
ORDER  BY NumberOfConnections DESC;
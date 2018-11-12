 -- Get Backup History for required database
 SELECT TOP 100
 s.database_name,
 m.physical_device_name,
 CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize,
 CAST(DATEDIFF(second, s.backup_start_date,
 s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken,
 s.backup_start_date,
 --CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn,
 --CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn,
 CASE s.[type]
 WHEN 'D' THEN 'Full'
 WHEN 'I' THEN 'Differential'
 WHEN 'L' THEN 'Transaction Log'
 END AS BackupType,
 s.server_name,
 s.recovery_model
 FROM msdb.dbo.backupset s
 INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
 WHERE s.type = 'D' and backup_start_date > '2016-02-02 23:00:00' -- AND S.database_name NOT LIKE 'm%'
  and database_name not in ('master','msdb','model','tempdb')
 ORDER BY backup_start_date DESC, s.database_name
 GO
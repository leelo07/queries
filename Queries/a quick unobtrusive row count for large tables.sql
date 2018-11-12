SELECT 
so.NAME TblName,
MAX(si.ROWS) RowCt
FROM sysobjects so,sysindexes si
WHERE so.xtype = 'U'
  AND si.id= OBJECT_ID(so.name)
GROUP BY
so.NAME
ORDER BY 
2 DESC 

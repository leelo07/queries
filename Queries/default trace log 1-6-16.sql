--SELECT * FROM sys.traces
SELECT * FROM fn_trace_getinfo(default);
Go
SELECT * 
FROM fn_trace_gettable
('C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_162.trc', default)
GO


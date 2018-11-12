use master
go
if exists ( select * from tempdb.dbo.sysobjects o
	    where o.xtype in ('U') and o.id = object_id( N'tempdb..#DB_FILE_INFO' ))
	drop table #DB_FILE_INFO
go

if exists ( select * from tempdb.dbo.sysobjects o
	    where o.xtype in ('U') and o.id = object_id( N'tempdb..#DB_INFO' ))
	drop table #DB_INFO
go
set nocount on
go
create table #DB_FILE_INFO (
	[ID]			int		not null
		identity (1, 1) primary key  clustered ,
	[DATABASE_NAME]		sysname		not null ,
	[FILEGROUP_TYPE]	nvarchar(4)	not null ,
	[FILEGROUP_ID]		smallint	not null ,
	[FILEGROUP]		sysname		not null ,
	[FILEID]		smallint	not null ,
	[FILENAME]		sysname		not null ,
	[DISK]			nvarchar(1)	not null ,
	[FILEPATH]		nvarchar(260)	not null ,
	[MAX_FILE_SIZE]		int		null ,
	[FILE_SIZE]		int		not null ,
	[FILE_SIZE_USED]	int		not null ,
	[FILE_SIZE_UNUSED]	int		not null ,
	[DATA_SIZE]		int		not null ,
	[DATA_SIZE_USED]	int		not null ,
	[DATA_SIZE_UNUSED]	int		not null ,
	[LOG_SIZE]		int		not null ,
	[LOG_SIZE_USED]		int		not null ,
	[LOG_SIZE_UNUSED]	int		not null ,
)
go

declare @sql	nvarchar(4000)
set @sql =
'use ['+'?'+'] ;
if db_name() <> N''?'' goto Error_Exit

insert into #DB_FILE_INFO
	(
	[DATABASE_NAME],
	[FILEGROUP_TYPE],
	[FILEGROUP_ID],
	[FILEGROUP],
	[FILEID],
	[FILENAME],
	[DISK],
	[FILEPATH],
	[MAX_FILE_SIZE],
	[FILE_SIZE],
	[FILE_SIZE_USED],
	[FILE_SIZE_UNUSED],
	[DATA_SIZE],
	[DATA_SIZE_USED],
	[DATA_SIZE_UNUSED],
	[LOG_SIZE],
	[LOG_SIZE_USED],
	[LOG_SIZE_UNUSED]
	)
select	top 100 percent
	[DATABASE_NAME] 	= db_name(),
	[FILEGROUP_TYPE]	= case when a.groupid = 0 then ''Log'' else ''Data'' end,
	[FILEGROUP_ID]		= a.groupid,
	a.[FILEGROUP],
	[FILEID]		= a.fileid,
	[FILENAME]		= a.name,
	[DISK]			= upper(substring(a.filename,1,1)),
	[FILEPATH]		= a.filename,
	[MAX_FILE_SIZE] =
		convert(int,round(
		(case a.maxsize when -1 then null else a.maxsize end*1.000)/128.000
		,0)),
	[FILE_SIZE]		= a.[fl_size],
	[FILE_SIZE_USED] 	= a.[fl_used],
	[FILE_SIZE_UNUSED] 	= a.[fl_unused],
	[DATA_SIZE]		= case when a.groupid <> 0 then a.[fl_size] else 0 end,
	[DATA_SIZE_USED]	= case when a.groupid <> 0 then a.[fl_used] else 0 end,
	[DATA_SIZE_UNUSED] 	= case when a.groupid <> 0 then a.[fl_unused] else 0 end,
	[LOG_SIZE] 		= case when a.groupid = 0 then a.[fl_size] else 0 end,
	[LOG_SIZE_USED] 	= case when a.groupid = 0 then a.[fl_used] else 0 end,
	[LOG_SIZE_UNUSED] 	= case when a.groupid = 0 then a.[fl_unused] else 0 end
from
	(
	Select
		aa.*,
		[FILEGROUP]	= isnull(bb.groupname,''''),
		-- All sizes are calculated in MB
		[fl_size]	= 
			convert(int,round((aa.size*1.000)/128.000,0)),
		[fl_used]	=
			convert(int,round(fileproperty(aa.name,''SpaceUsed'')/128.000,0)),
		[fl_unused]	=
			convert(int,round((aa.size-fileproperty(aa.name,''SpaceUsed''))/128.000,0))
	from
		dbo.sysfiles aa
		left join
		dbo.sysfilegroups bb
		on ( aa.groupid = bb.groupid )
	) a
order by
	case when a.groupid = 0 then 0 else 1 end,
	a.[FILEGROUP],
	a.name

Error_Exit:

'

--print @sql

exec sp_msforeachdb @sql

--select * from #DB_FILE_INFO

declare @DATABASE_NAME_LEN	varchar(20)
declare @FILEGROUP_LEN	varchar(20)
declare @FILENAME_LEN	varchar(20)
declare @FILEPATH_LEN	varchar(20)

select 
	@DATABASE_NAME_LEN	= convert(varchar(20),max(len(rtrim(DATABASE_NAME)))),
	@FILEGROUP_LEN	= convert(varchar(20),max(len(rtrim(FILEGROUP)))),
	@FILENAME_LEN	= convert(varchar(20),max(len(rtrim(FILENAME)))),
	@FILEPATH_LEN	= convert(varchar(20),max(len(rtrim(FILEPATH))))
from
	#DB_FILE_INFO

if object_id('tempdb..##DB_Size_Info_D115CA380E2B4538B6CBBB51') is not null
	begin
	drop table ##DB_Size_Info_D115CA380E2B4538B6CBBB51
	end

-- Setup code to reduce column sizes to max used
set @sql =
'
select
	[DATABASE_NAME]		= convert(varchar('+@DATABASE_NAME_LEN+'), a.[DATABASE_NAME] ),
	a.[FILEGROUP_TYPE],
	[FILEGROUP_ID],
	[FILEGROUP]		= convert(varchar('+@FILEGROUP_LEN+'), a.[FILEGROUP]),
	[FILEID],
	[FILENAME]		= convert(varchar('+@FILENAME_LEN+'), a.[FILENAME] ),
	a.[DISK],
	[FILEPATH]		= convert(varchar('+@FILEPATH_LEN+'), a.[FILEPATH] ),
	a.[MAX_FILE_SIZE],
	a.[FILE_SIZE],
	a.[FILE_SIZE_USED],
	a.[FILE_SIZE_UNUSED],
	FILE_USED_PCT	=
		convert(numeric(5,1),round(
		case
		when a.[FILE_SIZE] is null or a.[FILE_SIZE] = 0
		then NULL
		else (100.00000*a.[FILE_SIZE_USED])/(1.00000*a.[FILE_SIZE])
		end ,1)) ,
	a.[DATA_SIZE],
	a.[DATA_SIZE_USED],
	a.[DATA_SIZE_UNUSED],
	a.[LOG_SIZE],
	a.[LOG_SIZE_USED],
	a.[LOG_SIZE_UNUSED]
into
	##DB_Size_Info_D115CA380E2B4538B6CBBB51
from
	#DB_FILE_INFO a
order by
	a.[DATABASE_NAME],
	case a.[FILEGROUP_ID] when 0 then 0 else 1 end,
	a.[FILENAME]
'

--print @sql

exec ( @sql )

select	top 100 percent
	*
into
	#DB_INFO
from
	##DB_Size_Info_D115CA380E2B4538B6CBBB51 a
order by
	a.[DATABASE_NAME],
	case a.[FILEGROUP_ID] when 0 then 0 else 1 end,
	a.[FILENAME]

drop table ##DB_Size_Info_D115CA380E2B4538B6CBBB51

set nocount off

print 'Show Details'
select * from #DB_INFO

print 'Total by Database and File'
select
	[DATABASE_NAME]		= isnull([DATABASE_NAME],'  All Databases'),
	[FILENAME]		= isnull([FILENAME],''),
	FILE_SIZE		= sum(FILE_SIZE),
	FILE_SIZE_USED		= sum(FILE_SIZE_USED),
	FILE_SIZE_UNUSED	= sum(FILE_SIZE_UNUSED),
	FILE_USED_PCT	=
		convert(numeric(5,1),round(
		case
		when sum(a.[FILE_SIZE]) is null or sum(a.[FILE_SIZE]) = 0
		then NULL
		else (100.00000*sum(a.[FILE_SIZE_USED]))/(1.00000*sum(a.[FILE_SIZE]))
		end ,1)) ,
	DATA_SIZE		= sum(DATA_SIZE),
	DATA_SIZE_USED		= sum(DATA_SIZE_USED),
	DATA_SIZE_UNUSED	= sum(DATA_SIZE_UNUSED),
	LOG_SIZE		= sum(LOG_SIZE),
	LOG_SIZE_USED		= sum(LOG_SIZE_USED),
	LOG_SIZE_UNUSED		= sum(LOG_SIZE_UNUSED)
from
	#DB_INFO a
group by
	[DATABASE_NAME],
	[FILENAME]
	with rollup
order by
	case when [DATABASE_NAME] is null then 1 else 0 end ,
	[DATABASE_NAME],
	case when [FILENAME] is null then 1 else 0 end ,
	[FILENAME]


print 'Total by Database and Filegroup'

select
	--[Server]		= convert(varchar(15),@@servername),
	[DATABASE_NAME]		= isnull([DATABASE_NAME],'** Total **'),
	[FILEGROUP]			= 
		case when [FILEGROUP] is null then '' when [FILEGROUP] = '' then 'LOG' else [FILEGROUP] end,
	FILE_SIZE		= sum(FILE_SIZE),
	FILE_SIZE_USED		= sum(FILE_SIZE_USED),
	FILE_SIZE_UNUSED	= sum(FILE_SIZE_UNUSED),
	FILE_USED_PCT	=
		convert(numeric(5,1),round(
		case
		when sum(a.[FILE_SIZE]) is null or sum(a.[FILE_SIZE]) = 0
		then NULL
		else (100.00000*sum(a.[FILE_SIZE_USED]))/(1.00000*sum(a.[FILE_SIZE]))
		end ,1)) ,
	--MAX_SIZE		= SUM([MAX_FILE_SIZE]),
	DATA_SIZE		= sum(DATA_SIZE),
	DATA_SIZE_USED		= sum(DATA_SIZE_USED),
	DATA_SIZE_UNUSED	= sum(DATA_SIZE_UNUSED),
	LOG_SIZE		= sum(LOG_SIZE),
	LOG_SIZE_USED		= sum(LOG_SIZE_USED),
	LOG_SIZE_USED		= sum(LOG_SIZE_UNUSED)
from
	#DB_INFO A
group by
	[DATABASE_NAME],
	[FILEGROUP]
	with rollup
order by
	case when [DATABASE_NAME] is null then 1 else 0 end ,
	[DATABASE_NAME],
	case when [FILEGROUP] is null then 10 when [FILEGROUP] = '' then 0 else 1 end ,
	[FILEGROUP]


print 'Total by Database and Filegroup Type'

select
	--[Server]		= convert(varchar(15),@@servername),
	[DATABASE_NAME]		= isnull([DATABASE_NAME],'** Total **'),
	[FILEGROUP_TYPE]	= isnull([FILEGROUP_TYPE],''),
	FILE_SIZE		= sum(FILE_SIZE),
	FILE_SIZE_USED		= sum(FILE_SIZE_USED),
	FILE_SIZE_UNUSED	= sum(FILE_SIZE_UNUSED),
	FILE_USED_PCT	=
		convert(numeric(5,1),round(
		case
		when sum(a.[FILE_SIZE]) is null or sum(a.[FILE_SIZE]) = 0
		then NULL
		else (100.00000*sum(a.[FILE_SIZE_USED]))/(1.00000*sum(a.[FILE_SIZE]))
		end ,1)) ,
	DATA_SIZE		= sum(DATA_SIZE),
	DATA_SIZE_USED		= sum(DATA_SIZE_USED),
	DATA_SIZE_UNUSED	= sum(DATA_SIZE_UNUSED),
	LOG_SIZE		= sum(LOG_SIZE),
	LOG_SIZE_USED		= sum(LOG_SIZE_USED),
	LOG_SIZE_USED		= sum(LOG_SIZE_UNUSED)
from
	#DB_INFO A
group by
	[DATABASE_NAME],
	[FILEGROUP_TYPE]
	with rollup
order by
	case when [DATABASE_NAME] is null then 1 else 0 end ,
	[DATABASE_NAME],
	case when [FILEGROUP_TYPE] is null then 10 when [FILEGROUP_TYPE] = 'Log' then 0 else 1 end


print 'Total by Disk, Database, and Filepath'
select
	[DISK]			= isnull([DISK],''),
	[DATABASE_NAME]		= isnull([DATABASE_NAME],''),
	[FILEPATH]		= isnull([FILEPATH],''),
	FILE_SIZE		= sum(FILE_SIZE),
	FILE_SIZE_USED		= sum(FILE_SIZE_USED),
	FILE_SIZE_UNUSED	= sum(FILE_SIZE_UNUSED),
	FILE_USED_PCT	=
		convert(numeric(5,1),round(
		case
		when sum(a.[FILE_SIZE]) is null or sum(a.[FILE_SIZE]) = 0
		then NULL
		else (100.00000*sum(a.[FILE_SIZE_USED]))/(1.00000*sum(a.[FILE_SIZE]))
		end ,1)) ,
	DATA_SIZE		= sum(DATA_SIZE),
	DATA_SIZE_USED		= sum(DATA_SIZE_USED),
	DATA_SIZE_UNUSED	= sum(DATA_SIZE_UNUSED),
	LOG_SIZE		= sum(LOG_SIZE),
	LOG_SIZE_USED		= sum(LOG_SIZE_USED),
	LOG_SIZE_UNUSED		= sum(LOG_SIZE_UNUSED)
from
	#DB_INFO a
group by
	[DISK], 
	[DATABASE_NAME],
	[FILEPATH]
	with rollup
order by
	case when [DISK] is null then 1 else 0 end ,
	[DISK],
	case when [DATABASE_NAME] is null then 1 else 0 end ,
	[DATABASE_NAME],
	case when [FILEPATH] is null then 1 else 0 end ,
	[FILEPATH]



print 'Total by Disk and Database'
select
	[DISK]			= isnull([DISK],''),
	[DATABASE_NAME]		= isnull([DATABASE_NAME],''),
	FILE_SIZE		= sum(FILE_SIZE),
	FILE_SIZE_USED		= sum(FILE_SIZE_USED),
	FILE_SIZE_UNUSED	= sum(FILE_SIZE_UNUSED),
	FILE_USED_PCT	=
		convert(numeric(5,1),round(
		case
		when sum(a.[FILE_SIZE]) is null or sum(a.[FILE_SIZE]) = 0
		then NULL
		else (100.00000*sum(a.[FILE_SIZE_USED]))/(1.00000*sum(a.[FILE_SIZE]))
		end ,1)) ,
	DATA_SIZE		= sum(DATA_SIZE),
	DATA_SIZE_USED		= sum(DATA_SIZE_USED),
	DATA_SIZE_UNUSED	= sum(DATA_SIZE_UNUSED),
	LOG_SIZE		= sum(LOG_SIZE),
	LOG_SIZE_USED		= sum(LOG_SIZE_USED),
	LOG_SIZE_USED		= sum(LOG_SIZE_UNUSED)
from
	#DB_INFO a
group by
	[DISK], 
	[DATABASE_NAME]
	with rollup
order by
	case when [DISK] is null then 1 else 0 end ,
	[DISK],
	case when [DATABASE_NAME] is null then 1 else 0 end ,
	[DATABASE_NAME]



print 'Total by Disk'
select
	[DISK]			= isnull([DISK],''),
	FILE_SIZE		= sum(FILE_SIZE),
	FILE_SIZE_USED		= sum(FILE_SIZE_USED),
	FILE_SIZE_UNUSED	= sum(FILE_SIZE_UNUSED),
	FILE_USED_PCT	=
		convert(numeric(5,1),round(
		case
		when sum(a.[FILE_SIZE]) is null or sum(a.[FILE_SIZE]) = 0
		then NULL
		else (100.00000*sum(a.[FILE_SIZE_USED]))/(1.00000*sum(a.[FILE_SIZE]))
		end ,1)) ,
	DATA_SIZE		= sum(DATA_SIZE),
	DATA_SIZE_USED		= sum(DATA_SIZE_USED),
	DATA_SIZE_UNUSED	= sum(DATA_SIZE_UNUSED),
	LOG_SIZE		= sum(LOG_SIZE),
	LOG_SIZE_USED		= sum(LOG_SIZE_USED),
	LOG_SIZE_USED		= sum(LOG_SIZE_UNUSED)
from
	#DB_INFO a
group by
	[DISK]
	with rollup
order by
	case when [DISK] is null then 1 else 0 end ,
	[DISK]


print 'Total by Database'
select
	--[Server]		= convert(varchar(20),@@servername),
	[DATABASE_NAME]		= isnull([DATABASE_NAME],'** Total **'),
	FILE_SIZE		= sum(FILE_SIZE),
	FILE_SIZE_USED		= sum(FILE_SIZE_USED),
	FILE_SIZE_UNUSED	= sum(FILE_SIZE_UNUSED),
	FILE_USED_PCT	=
		convert(numeric(5,1),round(
		case
		when sum(a.[FILE_SIZE]) is null or sum(a.[FILE_SIZE]) = 0
		then NULL
		else (100.00000*sum(a.[FILE_SIZE_USED]))/(1.00000*sum(a.[FILE_SIZE]))
		end ,1)) ,
	DATA_SIZE		= sum(DATA_SIZE),
	DATA_SIZE_USED		= sum(DATA_SIZE_USED),
	DATA_SIZE_UNUSED	= sum(DATA_SIZE_UNUSED),
	LOG_SIZE		= sum(LOG_SIZE),
	LOG_SIZE_USED		= sum(LOG_SIZE_USED),
	LOG_SIZE_UNUSED		= sum(LOG_SIZE_UNUSED)
from
	#DB_INFO A
group by
	[DATABASE_NAME]
	with rollup
order by
	case when [DATABASE_NAME] is null then 1 else 0 end ,
	[DATABASE_NAME]



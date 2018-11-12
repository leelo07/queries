Set NoCount On
--Check to see the temp table exists
IF EXISTS ( SELECT  Name
            FROM    tempdb..sysobjects
            Where   name like '#HoldforEachDB%' )
--If So Drop it
    DROP TABLE #HoldforEachDB_size
--Recreate it
CREATE TABLE #HoldforEachDB_size
    (
      [DatabaseName] [nvarchar](75) COLLATE SQL_Latin1_General_CP1_CI_AS
                                    NOT NULL,
      [Size] [decimal] NOT NULL,
      [Name] [nvarchar](75) COLLATE SQL_Latin1_General_CP1_CI_AS
                            NOT NULL,
      [Filename] [nvarchar](90) COLLATE SQL_Latin1_General_CP1_CI_AS
                                NOT NULL,

    )
ON  [PRIMARY]

IF EXISTS ( SELECT  name
            FROM    tempdb..sysobjects
            Where   name like '#fixed_drives%' )
--If So Drop it
    DROP TABLE #fixed_drives
--Recreate it
CREATE TABLE #fixed_drives
    (
      [Drive] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS
                        NOT NULL,
      [MBFree] [decimal] NOT NULL
    )
ON  [PRIMARY]
--Insert rows from sp_MSForEachDB into temp table
INSERT  INTO #HoldforEachDB_size
        EXEC sp_MSforeachdb 'Select ''?'' as DatabaseName, Case When [?]..sysfiles.size * 8 / 1024 = 0 Then 1 Else [?]..sysfiles.size * 8 / 1024 End
AS size,[?]..sysfiles.name,
[?]..sysfiles.filename From [?]..sysfiles'
--Select all rows from temp table (the temp table will auto delete when the connection is gone.

INSERT  INTO #fixed_drives
        EXEC xp_fixeddrives


Select  @@Servername
print '' ;
Select  rtrim(Cast(DatabaseName as varchar(75))) as DatabaseName,
        Drive,
        Filename,
        Cast(Size as int) AS Size,
        Cast(MBFree as varchar(10)) as MB_Free
from    #HoldforEachDB_size
        INNER JOIN #fixed_drives ON LEFT(#HoldforEachDB_size.Filename, 1) = #fixed_drives.Drive
GROUP BY DatabaseName,
        Drive,
        MBFree,
        Filename,
        Cast(Size as int)
ORDER BY Drive,
        Size Desc
print '' ;
Select  Drive as [Total Data Space Used |],
        Cast(Sum(Size) as varchar(10)) as [Total Size],
        Cast(MBFree as varchar(10)) as MB_Free
from    #HoldforEachDB_size
        INNER JOIN #fixed_drives ON LEFT(#HoldforEachDB_size.Filename, 1) = #fixed_drives.Drive
Group by Drive,
        MBFree
print '' ;
Select  count(Distinct rtrim(Cast(DatabaseName as varchar(75)))) as Database_Count
from    #HoldforEachDB_size 

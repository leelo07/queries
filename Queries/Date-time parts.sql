select *, datepart(yy, ApprovedDate) as year 
,datepart(mm, ApprovedDate) as month
,datepart(dd, ApprovedDate) as day
,datepart(hh, ApprovedDate) as hour
,datepart(mi, ApprovedDate) as minute
,datepart(SS, ApprovedDate) as second
,datepart(ms, ApprovedDate) as millisecond
,datepart(ns, ApprovedDate) as nanosecond
from MgmtTraining
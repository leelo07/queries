SELECT *,sum(Amount) over() as companyTotal, 
	 Amount/SUM(amount) over() * 100 as percentOfTotal 
  FROM [JProCo].[dbo].[Grant]
--where GrantID = 1


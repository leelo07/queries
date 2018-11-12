SELECT [ProductName]
      ,[RetailPrice] 
      ,[Category]
      , AVG(retailPrice) over() as AvgPrice
      , avg(retailprice) over(partition by Category) as AvgCatPrice
  FROM [JProCo].[dbo].[CurrentProducts]




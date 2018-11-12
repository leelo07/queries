SELECT distinct [Category] 
      , count(*) over(partition by Category) * 100.0 / count(*) over() as PctCategory
  FROM [JProCo].[dbo].[CurrentProducts]




SELECT e.firstname
      ,e.lastname
      ,g.grantname
      ,l.city
      , g.amount
	  , sum(g.amount) over(partition by l.city)  
FROM Employee AS e 
INNER JOIN [Grant] AS g ON e.EmpID = g.EmpID 
INNER JOIN Location AS l ON l.LocationID = e.LocationID




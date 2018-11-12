Select Table_Name, Count(*) As ColumnCount
From Information_Schema.Columns
Group By Table_Name
Order By Table_Name

-- Xinan Wang NUID 002916472

USE AdventureWorks2008R2;

-- Question 3 (3pt)

/* Write a query to retrieve colors which have been sold in more than 14 mounths of different years as reflected
by the data stored in AdventureWorks. Exclude products which don't have a color specified for this query.

Include the color, and number of months a color has been sold in for the returned data. Sort the returned data 
by color. Use AdventureWorks2008R2 for this question.  */

WITH temp AS (SELECT Color, COUNT(DISTINCT MONTH(OrderDate))[Number of months], YEAR(OrderDate)[Yearnum]
			FROM Production.Product p
			INNER JOIN Sales.SalesOrderDetail sod
			ON p.ProductID = sod.ProductID 
			INNER JOIN Sales.SalesOrderHeader soh 
			ON sod.SalesOrderID = soh.SalesOrderID
			GROUP BY Color,YEAR(OrderDate))
SELECT Color,[Number of months]
FROM temp
WHERE [Number of months] > 14
ORDER BY Color;
	

-- Question 4 (4pt)

/* Write a query to retrieve the least valuable salesperson of each city. The least valuable salesperson has the
smallest sales amount in a city. Use TotalDue in SalesOrderHeader for calculating the sales amount. Use BillToAddressID
in SalesOrderHeader to determine what city an order is related to. Exclude orders which don't have a salesperson specified.

Return only the salesperson who has sold more than $650000 in the same city and has done business in more than one sales
territory. If there is a tie, your solution must retrieve it.

Include city, SalesPersonID, salesperson's last and first names, and Total sales of the least valuable salespersons in the 
same city for the returned data. Sort the returned data by City.  */

WITH SalePerson AS (SELECT BillToAddressID[City],FirstName[Salesperson's First Name], LastName[Salesperson's Last Name],
					SUM(TotalDue)[Total sales],sp.BusinessEntityID [SalespersonID],
					RANK() OVER (PARTITION BY BillToAddressID ORDER BY SUM(TotalDue) ASC) AS Ranking
				FROM Sales.SalesOrderHeader soh
				INNER JOIN Sales.SalesPerson sp
				ON soh.TerritoryID = sp.TerritoryID
				INNER JOIN HumanResources.Employee em
				ON em.BusinessEntityID = sp.BusinessEntityID
				INNER JOIN Person.Person p
				ON p.BusinessEntityID = em.BusinessEntityID
				GROUP BY BillToAddressID,sp.BusinessEntityID,FirstName,LastName),
Territorytrack AS (SELECT BusinessEntityID,COUNT(DISTINCT TerritoryID)[TerritoryNum]
				FROM Sales.SalesPerson
				GROUP BY BusinessEntityID
				HAVING COUNT(DISTINCT TerritoryID) <= 1),
SumCity AS (SELECT sp.BusinessEntityID, SUM(TotalDue)[Total sales], BillToAddressID[City]
			FROM Sales.SalesOrderHeader soh 
			INNER JOIN Sales.SalesPerson sp 
			ON soh.CustomerID = sp.BusinessEntityID
			GROUP BY sp.BusinessEntityID, BillToAddressID
			HAVING SUM(TotalDue) <= 650000)
SELECT [City],[SalespersonID],[Salesperson's First Name],[Salesperson's Last Name],[Total sales]
FROM SalePerson
WHERE Ranking = 1 AND [SalespersonID] NOT IN(SELECT BusinessEntityID FROM Territorytrack)
				AND [SalespersonID] NOT IN (SELECT BusinessEntityID FROM SumCity)
ORDER BY [City];




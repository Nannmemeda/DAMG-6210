
-- Second Last Digit of your NUID: 0, 1, 2, 3, 4, or 7

-- Your NUID: 002916472

-- Your Name: Xinan Wang


use adventureworks2008r2;

-- Question 1 (4 points)

/* Rewrite the following query to present the same data in a horizontal format,
   as listed below, using the SQL PIVOT command.
   
   Please use AdventureWorks2008R2 for this question. */

SELECT DATENAME(mm, OrderDate) AS [Month], Color,
       SUM(OrderQty) AS TotalQuantity
FROM   Sales.SalesOrderHeader sh
JOIN Sales.SalesOrderDetail sd
ON sh.SalesOrderID = sd.SalesOrderID
JOIN Production.Product p
ON p.ProductID = sd.ProductID
WHERE Color in ('Black' , 'Red' , 'Yellow') and MONTH(OrderDate) between 1 and 6
GROUP BY Color, DATENAME(mm, OrderDate), MONTH(OrderDate)
ORDER BY MONTH(OrderDate);

/*
Month		Black	Red		Yellow
January		3801	1523	1666
February	5726	2329	2195
March		4840	1776	2181
April		5786	2107	2238
May			8125	3213	3199
June		6998	2461	2986
*/

WITH temp AS(
	SELECT DATENAME(mm,OrderDate)[OrderMonth], Color, SUM(OrderQty)[TotalSoldQty]
	FROM   Sales.SalesOrderHeader sh
	JOIN Sales.SalesOrderDetail sd
	ON sh.SalesOrderID = sd.SalesOrderID
	JOIN Production.Product p
	ON p.ProductID = sd.ProductID
	WHERE MONTH(OrderDate) BETWEEN 1 AND 6
	GROUP BY Color,DATENAME(mm,OrderDate))	
SELECT Month(OrderMonth)[Month], [Black],[Red],[Yellow]
FROM (SELECT OrderMonth,Color,TotalSoldQty FROM temp) vertical
PIVOT(MAX(TotalSoldQty) FOR Month(OrderMonth) IN ([Black],[Red],[Yellow])) PivotTable
ORDER BY MONTH(OrderMonth + ' 1 2018');


-- Question 2 (5 points)

/*
Using AdventureWorks2008R2, write a query to retrieve 
the customers and their order info.

Return a customer's id, a customer's total order count,
the lowest total product quantity contained in an order 
for all orders of a customer, and a customer's bottom 3 orders.
The returned data should have the format displayed below.

For the lowest total product quantity contained in an order 
for all orders of a customer, an example is:

Mary has 3 orders.

Order #1 has a total sold quantity of 10
Order #2 has a total sold quantity of 25
Order #3 has a total sold quantity of 21

Then the lowest total product quantity contained in an order 
for all orders of Mary is 10.

The bottom 3 orders have the 3 lowest order values. 
Use TotalDue in SalesOrderHeader as the order value. If there 
is a tie, the tie must be retrieved.

Include only the customers who have more than 27 orders.

Sort the returned data by CustomerID.
*/


/*
CustomerID	OrderCount	ProductCount	OrderValues
11091			28			1			2.53, 5.51, 6.94
11176			28			1			2.53, 5.51, 6.94
*/

WITH bottomOrder AS(
	SELECT CustomerID,SalesOrderID, TotalDue[OrderValue],
		RANK() OVER (PARTITION BY CustomerID ORDER BY TotalDue ASC) AS Ranking
	FROM Sales.SalesOrderHeader),
minProductCount AS(
	SELECT CustomerID, MIN(OrderQty)[MinProduct]
	FROM Sales.SalesOrderDetail sod
	JOIN Sales.SalesOrderHeader soh 
	ON sod.SalesOrderID = soh.SalesOrderID 
	GROUP BY CustomerID
	)
	
SELECT CustomerID, SUM(SalesOrderID)[OrderCount], 
	(SELECT MinProduct FROM minProductCount mpc WHERE soh.CustomerID = mpc.CustomerID) [ProductCount],
	STUFF((SELECT ', ' + RTRIM(CAST(OrderValue AS VARCHAR))
		FROM bottomOrder bo
		WHERE bo.CustomerID = soh.CustomerID AND Ranking <= 3
		FOR XML PATH('')), 1, 2,'') [OrderValues]
FROM Sales.SalesOrderHeader soh 
ORDER BY CustomerID;
	




-- Question 3 (6 points)

/* Wang's Golf Course charges a deposit for rental equipment.
   There is a $100 deposit for each piece of rental equipment. For example,
   if the quantity of rental equipment is 5, then the deposit amount 
   is $500. For an order, the cap of the deposit is $1000. In other words,
   the maximum deposit for an order is $1000. If a customer has the Gold 
   membership, the deposit is waived.

   Given the following tables, write a trigger to calculate 
   the deposit for an order. Save the deposit amount in the 
   Deposit column of the SalesOrder table. */

USE NancyDB;

create table Customer
(CustomerID int primary key,
 LastName varchar(50),
 FirstName varchar(50),
 Membership varchar(10));

create table SalesOrder
(OrderID int primary key,
 CustomerID int references Customer(CustomerID),
 OrderDate date,
 Deposit money,
 Tax as OrderValue * 0.08,
 OrderValue money);

create table OrderDetail
(OrderID int references SalesOrder(OrderID),
 ProductID int,
 Quantity int,
 UnitPrice money
 primary key(OrderID, ProductID));


CREATE TRIGGER depositAmount
ON SalesOrder 
FOR INSERT, UPDATE, DELETE
AS
	BEGIN
		
		DECLARE @AmountDeposit MONEY;
		DECLARE @Customid INT;
		
		SELECT @Customid  = ISNULL(i.CustomerID,d.CustomerID)
		FROM inserted i
		JOIN deleted d
		ON i.CustomerID = d.CustomerID;
		
		SELECT @AmountDeposit = Quantity * 100
		FROM OrderDetail od
		JOIN SalesOrder so
		ON od.OrderID = so.OrderID
		WHERE CustomerID = @Customid;
		
		IF @AmountDeposit > 1000
			SET @AmountDeposit = 1000;
		
		SELECT @AmountDeposit = 0
		FROM Customer
		WHERE Membership = 'Gold'
		
		UPDATE SalesOrder
			SET Deposit = @AmountDeposit
			WHERE CustomerID = @Customid;
		
	END



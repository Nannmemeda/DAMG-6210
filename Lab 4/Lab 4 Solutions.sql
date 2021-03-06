
-- Lab 4 Solutions

-- Part A

CREATE DATABASE Dinggan;
USE Dinggan;

CREATE TABLE dbo.TargetCustomers(
TargetID int IDENTITY NOT NULL PRIMARY KEY,
FirstName varchar(40) NOT NULL,
LastName varchar(40) NOT NULL,
Address varchar(80) NOT NULL,
City varchar(30) NOT NULL,
State varchar(30) NOT NULL,
ZipCode varchar(10) NOT NULL);

CREATE TABLE dbo.MailingLists(
MailingListID int IDENTITY NOT NULL PRIMARY KEY,
MailingList varchar(80) NOT NULL);

CREATE TABLE dbo.TargetMailingLists(
TargetID int NOT NULL REFERENCES dbo.TargetCustomers(TargetID),
MailingListID int NOT NULL REFERENCES dbo.MailingLists(MailingListID)
CONSTRAINT PKTargetMailingLists PRIMARY KEY CLUSTERED 
(TargetID,MailingListID));

-- Part B

-- B-1

Use AdventureWorks2008R2;
SELECT distinct c.CustomerID,
COALESCE( STUFF((SELECT  distinct ', '+RTRIM(CAST(SalesPersonID as char))  
       FROM Sales.SalesOrderHeader 
       WHERE CustomerID = c.customerid
       FOR XML PATH('')) , 1, 2, '') , '')  AS SalesPersons
FROM Sales.Customer c
left join Sales.SalesOrderHeader oh on c.customerID = oh.CustomerID
order by c.CustomerID desc;


-- B-2
Use AdventureWorks2008R2
WITH Temp1 AS

   (select year(OrderDate) Year, ProductID, sum(OrderQty) ttl,
    rank() over (partition by year(OrderDate) order by sum(OrderQty) desc) as TopProduct
    from Sales.SalesOrderHeader sh
	join Sales.SalesOrderDetail sd
	on sh.SalesOrderID = sd.SalesOrderID
    group by year(OrderDate), ProductID) ,

Temp2 AS

   (select year(OrderDate) Year, sum(OrderQty) ttl
    from Sales.SalesOrderHeader sh
	join Sales.SalesOrderDetail sd
	on sh.SalesOrderID = sd.SalesOrderID
    group by year(OrderDate))

select t1.Year, cast(sum(t1.ttl) as decimal) / t2.ttl * 100 [% of Total Sale],

STUFF((SELECT  ', '+RTRIM(CAST(ProductID as char))  
       FROM temp1 
       WHERE Year = t1.Year and TopProduct <=5
       FOR XML PATH('')) , 1, 2, '') AS Top5Products

from temp1 t1
join temp2 t2
on t1.Year=t2.Year
where t1.TopProduct <= 5
group by t1.Year, t2.ttl;





-- Part C

WITH Parts(AssemblyID, ComponentID, PerAssemblyQty, EndDate, 
ComponentLevel,ListPrice) AS 
( 
    SELECT b.ProductAssemblyID, b.ComponentID, b.PerAssemblyQty, 
           b.EndDate, 0 AS ComponentLevel , p2.ListPrice
    FROM Production.BillOfMaterials AS b JOIN Production.Product p2
    ON b.ComponentID  = p2.ProductID WHERE b.ProductAssemblyID = 992 AND b.EndDate 
IS NULL 
 
    UNION ALL 
 
    SELECT bom.ProductAssemblyID, bom.ComponentID, p.PerAssemblyQty, 
           bom.EndDate, ComponentLevel + 1, p2.ListPrice  
    FROM Production.BillOfMaterials AS bom  
    INNER JOIN Parts AS p 
    ON bom.ProductAssemblyID = p.ComponentID AND bom.EndDate IS NULL 
    INNER JOIN Production.Product p2 ON p2.ProductID = bom.ComponentID  
) , 
ReducedPrice AS
( SELECT  SUM(p.ListPrice) as ListPricelevel1
FROM Production.BillOfMaterials bom 
JOIN Production.Product p ON bom.ComponentID = p.ProductID WHERE 
bom.ProductAssemblyID  = 815
GROUP BY bom.ProductAssemblyID 
)
SELECT (ListPrice - ListPricelevel1) AS ReducedPrice from Parts,ReducedPrice 
WHERE Parts.AssemblyID = 992 and Parts.ComponentID = 815


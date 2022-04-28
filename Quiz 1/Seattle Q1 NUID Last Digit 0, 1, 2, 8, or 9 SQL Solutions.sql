
-- Seattle Q1 NUID Last Digit 0, 1, 2, 8, or 9

-- Question 3 (3 points)

with temp1 as (
select p.Color, year(OrderDate) Year, month(OrderDate) Month
from [Sales].[SalesOrderHeader] sh
join [Sales].[SalesOrderDetail] od
     on sh.SalesOrderID = od.SalesOrderID
join Production.Product p
     on od.ProductID = p.ProductID
where color is not null
group by year(OrderDate), month(OrderDate), p.Color)

select Color, count(1) #Months
from temp1 
group by Color
having count(1) > 14 
order by color;



-- Question 4 (4 points)

with temp as (
select City, sh.SalesPersonID, p.LastName, p.FirstName, sum(TotalDue) TotalSales,
       rank() over (partition by City order by sum(TotalDue) asc) Ranking
from Sales.SalesOrderHeader sh
join Person.Address a
on sh.BillToAddressID = a.AddressID
join Person.Person p
on sh.SalesPersonID = p.BusinessEntityID
where SalesPersonID is not null
group by a.City, sh.SalesPersonID, p.LastName, p.FirstName),

temp2 as (
select SalesPersonID
from Sales.SalesOrderHeader
where SalesPersonID is not null
group by SalesPersonID
having count(distinct TerritoryID) > 1)

select * from temp where Ranking = 1 and TotalSales > 650000 and
                   SalesPersonID in (select * from temp2)
order by City;




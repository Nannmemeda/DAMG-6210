
-- Seattle Q1 NUID Last Digit 3, 4, 5, 6, or 7

-- Question 3 (3 points)

with temp1 as (
select od.ProductID, year(OrderDate) Year, datepart(qq, OrderDate) Quarter,
       sum(od.OrderQty) SoldQuantity
from [Sales].[SalesOrderHeader] sh
join [Sales].[SalesOrderDetail] od
     on sh.SalesOrderID = od.SalesOrderID
group by year(OrderDate), datepart(qq, OrderDate), od.ProductID)

select ProductID, count(1) #Quarters, sum(SoldQuantity) TotalSoldQuantity 
from temp1 
group by ProductID
having count(1) > 12
order by ProductID;



-- Question 4 (4 points)

with temp as (
select City, Color, sum(OrderQty) TotalSales,
       rank() over (partition by City order by sum(OrderQty) asc) Ranking
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
join Production.Product p
on sd.ProductID = p.ProductID
join Person.Address a
on sh.ShipToAddressID = a.AddressID
where Color is not null
group by a.City, Color),

temp2 as (
select Color, count(City) cc
from temp
group by Color
having count(distinct City) > 100)

select t.*, cc #ofCities 
from temp t
join temp2 t2
on t.Color = t2.Color
where Ranking = 1 and TotalSales > 100
order by City;



-- 2nd Last Digit of NUID 0, 1, 2, 3, 4, or 7

-- Question 1 (4 points)

SELECT [Month],
       [Black],
	   [Red],
	   [Yellow]
FROM (SELECT DATENAME(mm, OrderDate) AS [Month], Color,
       OrderQty
FROM   Sales.SalesOrderHeader sh
JOIN Sales.SalesOrderDetail sd
ON sh.SalesOrderID = sd.SalesOrderID
JOIN Production.Product p
ON p.ProductID = sd.ProductID
WHERE Color in ('Black' , 'Red' , 'Yellow') and MONTH(OrderDate) between 1 and 6
	  ) AS SourceTable
PIVOT
     (SUM(OrderQty)
      FOR Color IN ([Black] , [Red] , [Yellow])
     ) AS PivotTable
ORDER BY MONTH([Month]+ ' 1 2020');

-- OR

SELECT [Month], --m,
       [Black],
	   [Red],
	   [Yellow]
FROM (SELECT DATENAME(mm, OrderDate) AS [Month], Color,
       OrderQty, MONTH(OrderDate) m
FROM   Sales.SalesOrderHeader sh
JOIN Sales.SalesOrderDetail sd
ON sh.SalesOrderID = sd.SalesOrderID
JOIN Production.Product p
ON p.ProductID = sd.ProductID
WHERE Color in ('Black' , 'Red' , 'Yellow') and MONTH(OrderDate) between 1 and 6
	  ) AS SourceTable
PIVOT
     (SUM(OrderQty)
      FOR Color IN ([Black] , [Red] , [Yellow])
     ) AS PivotTable
ORDER BY m;


-- Question 2 (5 points)

with temp as (
select SalesOrderID, count(distinct sd.ProductID) Products
from Sales.SalesOrderDetail sd
group by SalesOrderID
)

select c.CustomerID, count(c.SalesOrderID) OrderCount, 
       min(Products) LowestTotalProductQuantity,

STUFF((SELECT  TOP 3 WITH TIES ', '+RTRIM(CAST(s.TotalDue as varchar))  
       FROM Sales.SalesOrderHeader s  
	   WHERE s.CustomerID = c.CustomerID
       ORDER BY TotalDue ASC
       FOR XML PATH('')) , 1, 2, '') AS OrderValues

from Sales.SalesOrderHeader c
join temp t
on c.SalesOrderID = t.SalesOrderID
group by c.CustomerID
having count(c.SalesOrderID) > 27
order by c.CustomerID;


-- Question 3 (6 points)

create trigger trDeposit on Orderdetail
after insert, update, delete
as
begin
   declare @TotalQuantity int, @oid int, @dp money, @m varchar(10), @c int;

   select @oid = coalesce(i.OrderID, d.OrderID)
			  from inserted i
			  full join deleted d
				   on i.OrderID=d.OrderID;

   set @c = (select CustomerID from SalesOrder
             where OrderID = @oid);
  
   set @m = (select Membership from Customer 
             where CustomerID = @c);

   if @m = 'Gold'
      set @dp = 0
   else
      begin
        set @TotalQuantity = (select sum(Quantity) from OrderDetail 
                              where OrderID = @oid);
        set @dp = 100 * @TotalQuantity;
        if @dp > 1000 set @dp = 1000;
      end

   update SalesOrder set Deposit = @dp
          where OrderID = @oid;
end

drop trigger trDeposit


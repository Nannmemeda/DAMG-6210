
-- 2nd Last Digit of NUID 5, 6, 8, or 9

-- Question 1 (4 points)

SELECT [Month],
       [6] 'Territory 6',
	   [7] 'Territory 7',
	   [8] 'Territory 8',
	   [9] 'Territory 9',
	   [10] 'Territory 10'
FROM (SELECT DATENAME(mm, OrderDate) AS [Month], TerritoryID, CAST(TotalDue AS int) TotalDue
      FROM Sales.SalesOrderHeader
      WHERE TerritoryID BETWEEN 6 AND 10 AND MONTH(OrderDate) between 7 and 12
	  ) AS SourceTable
PIVOT
     (SUM(TotalDue)
      FOR TerritoryID IN ([6], [7], [8], [9], [10])
     ) AS PivotTable
ORDER BY MONTH([Month]+ ' 1 2020');


-- Question 2 (5 points)

with temp as (
select h.SalesPersonID, h.SalesOrderID, sum(OrderQty) TotalQuantity,
       rank() over (order by sum(OrderQty) desc) Rank
from Sales.SalesOrderDetail d
join Sales.SalesOrderHeader h
on d.SalesOrderID = h.SalesOrderID
group by h.SalesOrderID, h.SalesPersonID
)

select c.SalesPersonID, count(distinct c.SalesOrderID) TotalOrderCount, 
       min(TotalQuantity) LowestQuantity,

STUFF((SELECT  TOP 3 WITH TIES ', '+RTRIM(CAST(s.TotalDue as varchar))  
       FROM Sales.SalesOrderHeader s  
	   WHERE s.SalesPersonID = c.SalesPersonID
       ORDER BY TotalDue ASC
       FOR XML PATH('')) , 1, 2, '') AS Lowest3Values

from Sales.SalesOrderHeader c
join temp t
on c.SalesPersonID = t.SalesPersonID
where Rank <= 3 --and SalesPersonID is not null
group by c.SalesPersonID
order by c.SalesPersonID;


-- Question 3 (6 points)

create trigger trShippingFee on Orderdetail
after insert, update, delete
as
begin
   declare @TotalQuantity int, @oid int, @fee money;

   set @oid = (select coalesce(i.OrderID, d.OrderID)
							   from inserted i
							   full join deleted d
							        on i.OrderID=d.OrderID);

   set @TotalQuantity = (select sum(Quantity) from OrderDetail 
                         where OrderID = @oid);
   
   if (select OrderValue from SalesOrder where OrderID = @oid) > 600
      set @fee = 2 * @TotalQuantity
      else set @fee = 4 * @TotalQuantity;

   update SalesOrder set ShippingFee = @fee
          where OrderID = @oid;
end

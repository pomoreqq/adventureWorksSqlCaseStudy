-- 📊 Sales Analysis – 25 pytań biznesowych
-- 🔹 Proste (fundamenty, 5 pytań)

-- Łączny przychód w każdym roku.
select extract(year from orderdate) as yr, round(sum(subtotal) / 1000000,2) as revenuePerYrInMilion
from sales.salesorderheader
group by yr
order by yr;
-- Liczba zamówień w każdym miesiącu.
select extract(year from orderdate) as yr,extract(month from orderdate) as mnth,count(*) as orderCount
from sales.salesorderheader
group by yr,mnth
order by yr,mnth;
-- Średnia wartość zamówienia w każdym roku.
select extract(year from orderdate) as yr,round(avg(totalDue),2) from sales.salesorderheader
group by yr
order by yr;
-- Top 10 produktów wg liczby sprzedanych sztuk.
select * from sales.salesorderheader -- tu mam orderid
select * from sales.salesorderdetail;
select * from production.product;
with cteCount as (
select productid,sum(orderqty) as sumQuantityPerProduct from sales.salesorderdetail
group by productid
order by sumQuantityPerProduct DESC
limit 10
)
select c.productid,c.sumquantityperproduct,p.name from cteCount c
left join production.product p
on c.productid = p.productid;
-- Liczba unikalnych klientów w każdym regionie sprzedaży (SalesTerritory).
select * from sales.salesterritory;
select * from sales.customer;

select st.territoryid,st.name, count(distinct c.customerid) as uniqueCustomerCount from sales.salesterritory st
inner join sales.customer c
on c.territoryid = st.territoryid
group by st.territoryid,st.name
order by uniquecustomercount DESC;
-- 🔹 Średnie (biznesowe, 10 pytań)

-- Udział sprzedaży kategorii Bikes w całkowitej sprzedaży rocznej (%).
select * from sales.salesorderheader;
select * from sales.salesorderdetail;
select * from production.product;
select * from production.productcategory;
select * from production.productsubcategory;
-- z orderheader wybieram tylko totaldue i order date
-- joinujemy z orderdetail po salesorderid
-- nastepnie z product po product id
-- nastepnie product z productsubcategory po productsubcategoryid
--nastepnie subcategory z category
with cte as (
select extract(year from soh.orderdate) as yr,round(sum(sod.orderqty * sod.unitprice * (1 - sod.unitpricediscount))/1000000,2) as bikesRevenuePerYrInMilion from sales.salesorderheader soh
inner join sales.salesorderdetail sod
on sod.salesorderid = soh.salesorderid
inner join production.product p
on sod.productid = p.productid
inner join production.productsubcategory psub
on p.productsubcategoryid = psub.productsubcategoryid
inner join production.productcategory pc
on pc.productcategoryid = psub.productcategoryid
where pc.name = 'Bikes'
group by yr
order by yr
),
	cte2 as (
		select extract(year from orderdate) as yr, round(sum(subtotal) / 1000000,2) as revenuePerYrInMilion
from sales.salesorderheader
group by yr
order by yr
)
select a.yr,a.revenueperyrinmilion,b.bikesRevenuePerYrInMilion,round((b.bikesRevenuePerYrInMilion/a.revenueperyrinmilion),2) * 100 as percentageOfRevenue from cte b
inner join cte2 a
on b.yr = a.yr;
	
-- Klienci, którzy wydali więcej niż 10 000 w całej historii (łącznie).
select * from sales.customer;
select * from sales.salesorderheader;
select * from person.person;
with cte as (
select customerid,sum(subtotal) as sumPerClient from sales.salesorderheader
group by customerid
having sum(subtotal) > 10000
order by sumPerClient desc
),
 cte2 as (select soh.customerid,p.firstname,p.lastname from sales.salesorderheader soh
inner join sales.customer c
on c.customerid = soh.customerid
inner join person.businessentity pbus
on c.personid = pbus.businessentityid
inner join person.person p
on pbus.businessentityid = p.businessentityid)
select b.firstname,b.lastname,a.sumPerClient from cte a
left join cte2 b
on b.customerid = a.customerid
-- Najczęściej sprzedawane produkty w każdym regionie (1 produkt per region).
select * from sales.salesorderheader;
select * from sales.salesorderdetail;


select * from sales.salesorderheader 
select * from sales.salesorderdetail;
select * from production.product;
with cteCount as (
select productid,sum(orderqty) as sumQuantityPerProduct,salesorderid from sales.salesorderdetail
group by productid,salesorderid
order by sumQuantityPerProduct DESC
),
cte2 as (select soh.territoryid,cteCount.productid,sum(cteCount.sumquantityperproduct) as sumProductTerritory from ctecount
inner join sales.salesorderheader soh
on ctecount.salesorderid = soh.salesorderid
inner join sales.salesterritory st
on st.territoryid = soh.territoryid
group by soh.territoryid,ctecount.productid
order by soh.territoryid,sumProductTerritory DESC),
cte3 as (select cte2.territoryid,cte2.productid,sumProductTerritory,st.name as tName,p.name as pName,
row_number() over(partition by cte2.territoryid order by sumproductterritory DESC) as rowNumber
from cte2
left join sales.salesterritory st
on cte2.territoryid=st.territoryid
left join production.product p
on p.productid = cte2.productid)
select tname,pname,sumproductterritory from cte3
where rowNumber = 1
-- Trend średniej wartości zamówienia miesiąc po miesiącu (MA – moving average).
with cte as (select extract(year from orderdate) as yr,extract(month from orderdate) as mnth,
round(avg(subtotal),2) as avgPerMonth from sales.salesorderheader
group by yr,mnth)
select *,avg(avgpermonth) over(order by yr,mnth rows between 1 preceding and current row)
from cte;
-- Liczba zamówień, w których sprzedano więcej niż 5 różnych produktów.
select salesorderid, count(distinct productid) as productCount from sales.salesorderdetail
group by salesorderid
having count(distinct productid) > 5 ;
-- Produkty, które były sprzedawane każdego roku w historii bazy.
select count(distinct extract(year from orderdate)) from sales.salesorderheader -- 4
;

select count(*) from (
select sod.productid,count(distinct extract(year from orderdate)) as uniqueYearsCount from sales.salesorderheader soh
inner join sales.salesorderdetail sod
on sod.salesorderid = soh.salesorderid
group by sod.productid
having count(distinct extract(year from orderdate)) = 4
) -- 24 produkty
-- Który sprzedawca (SalesPerson) miał najwyższą średnią wartość zamówienia?
with cte as (
select salespersonid,avg(subtotal) as avgOrderValue from sales.salesorderheader
group by salespersonid
order by avg(subtotal) desc
limit 1
)
select cte.salespersonid, cte.avgordervalue,p.firstname,p.lastname from cte
inner join sales.salesperson sp
on sp.businessentityid = cte.salespersonid
inner join person.person p
on sp.businessentityid = p.businessentityid;
-- Średnia liczba dni między zamówieniem a datą wysyłki (ShipDate).
select * from sales.salesorderheader
select avg(extract(day from age(shipdate, orderdate))) as avg_days from sales.salesorderheader
-- Klienci, którzy w 2013 kupili więcej niż 1 kategorię produktów (cross-sell).
select * from sales.salesorderdetail;
select * from sales.salesorderheader;

with cte as (
select soh.customerid, count(distinct pc.productcategoryid) as categoryCount from sales.salesorderheader soh
inner join sales.salesorderdetail sod
on sod.salesorderid = soh.salesorderid
inner join production.product p
on p.productid = sod.productid
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
inner join production.productcategory pc
on pc.productcategoryid = psc.productcategoryid
WHERE EXTRACT(YEAR FROM soh.orderdate) = 2013
group by soh.customerid
having count(distinct pc.productcategoryid) > 1
)
select cte.customerid,cte.categoryCount,p.firstname,p.lastname from cte
inner join sales.customer c
on cte.customerid = c.customerid
inner join person.person p
on p.businessentityid = c.personid;
-- Ranking regionów wg wzrostu sprzedaży rok do roku (% growth).
select * from sales.salesorderheader

with cte as (select territoryid,extract(year from orderdate) as yr, sum(subtotal) as totalPerTerritoryPerYear
from sales.salesorderheader
group by territoryid,yr),
cte2 as (select territoryid,yr,totalperterritoryperyear,
lag(totalperterritoryperyear) over(partition by territoryid order by yr) as priorYear
from cte),
cte3 as (select territoryid,yr,round(totalperterritoryperyear,2),prioryear,round((totalperterritoryperyear / prioryear),2) * 100
as percentageofgrowth from cte2)
select territoryid,yr,percentageofgrowth
from cte3
where percentageofgrowth is not null
order by percentageofgrowth desc;
-- 🔹 Zaawansowane (prawdziwe portfolio-level, 10 pytań)

-- Top 5 klientów w każdym roku pod względem przychodu (RANK() OVER PARTITION).
with cte as (
select extract(year from orderdate) as yr,customerid,sum(subtotal) as totalSum from sales.salesorderheader
group by yr,customerid
),
cte2 as (
select yr,customerid,totalsum,
rank() over(partition by yr order by totalsum desc) as rnk from cte
)
select * from cte2
where rnk <= 5;

-- Skumulowana sprzedaż (running total) miesiąc po miesiącu (SUM() OVER).
with cte as (
select extract(year from orderdate) as yr,extract(month from orderdate) as mnth,sum(subtotal) as totalSum
from sales.salesorderheader
group by yr,mnth
)
select yr,mnth,totalsum,
sum(totalsum) over(order by yr,mnth) as runningTotal
from cte;

-- Średni czas między kolejnymi zamówieniami per klient (LAG() na OrderDate).
with cte as (
select customerid,orderdate,
lag(orderdate) over(partition by customerid order by orderdate) as priorDay
from sales.salesorderheader
),
cte2 as (
select customerid,orderdate,priorday,(orderdate - priorday) as dayDiff from cte
)
select customerid,avg(daydiff) from cte2
group by customerid;

-- Klienci, którzy kupili Mountain Bikes ale nigdy Road Bikes (subquery lub EXCEPT).
select soh.customerid,sub.name from sales.salesorderheader soh
inner join sales.salesorderdetail sod
on sod.salesorderid = soh.salesorderid
inner join production.product p
on sod.productid = p.productid
inner join production.productsubcategory sub
on p.productsubcategoryid = sub.productsubcategoryid
where sub.name = 'Mountain Bikes' and soh.customerid not in (
	select soh2.customerid from sales.salesorderheader soh2
inner join sales.salesorderdetail sod2
on sod2.salesorderid = soh2.salesorderid
inner join production.product p2
on sod2.productid = p2.productid
inner join production.productsubcategory sub2
on p2.productsubcategoryid = sub2.productsubcategoryid
where sub2.name = 'Road Bikes'
)

-- leftjoin wersja

with cte as (
select soh.customerid,sub.name from sales.salesorderheader soh
inner join sales.salesorderdetail sod
on sod.salesorderid = soh.salesorderid
inner join production.product p
on sod.productid = p.productid
inner join production.productsubcategory sub
on p.productsubcategoryid = sub.productsubcategoryid
where sub.name = 'Mountain Bikes'
),
cte2 as (
select soh.customerid,sub.name from sales.salesorderheader soh
inner join sales.salesorderdetail sod
on sod.salesorderid = soh.salesorderid
inner join production.product p
on sod.productid = p.productid
inner join production.productsubcategory sub
on p.productsubcategoryid = sub.productsubcategoryid
where sub.name = 'Road Bikes'
)
select cte.customerid,cte.name from cte
left join cte2
on cte.customerid = cte2.customerid
where cte2.customerid is null;
-- Sprzedaż w podziale na rok i region z użyciem GROUPING SETS (analiza wielowymiarowa).
SELECT 
    EXTRACT(YEAR FROM orderdate) AS yr,
    soh.territoryid,
    SUM(subtotal) AS total_sales
FROM sales.salesorderheader soh
GROUP BY GROUPING SETS (
    (EXTRACT(YEAR FROM orderdate), soh.territoryid), -- rok + region
    (EXTRACT(YEAR FROM orderdate)),                  -- tylko rok
    (soh.territoryid)                                -- tylko region
);

-- Produkty, które generują 80% przychodu firmy (analiza Pareto / 80-20 rule).
select * from sales.salesorderdetail

with cte as (
select productid,round(sum((orderqty * unitprice) * (1-unitpricediscount)),2) as sumPerProduct from sales.salesorderdetail
group by productid
),
cte2 as (
select productid, sumPerProduct,(select sum(subtotal) from sales.salesorderheader) as totalSum,
sum(sumPerProduct) over(order by sumPerProduct DESC) as cumSum from cte
),
cte3 as (
select productid,totalsum,cumsum,round(cumsum/totalsum,2) as cumSumPercentage from cte2
where round(cumsum/totalsum,2) <= 0.8
)
select cte3.productid,p.name from cte3
left join production.product p
on cte3.productid = p.productid
where p.productid is not null;
-- Sprzedaż per produkt z udziałem procentowym w całkowitej sprzedaży (SUM() OVER ()).
with cte as (
select productid,round(sum((orderqty * unitprice) * (1-unitpricediscount)),2) as sumPerProduct from sales.salesorderdetail
group by productid
),
cte2 as (
select productid, sumPerProduct,(select sum(subtotal) from sales.salesorderheader)
as totalSum from cte
)
select productid, round(sumperproduct/totalsum,4) from cte2;


-- Zmiana średniej wartości zamówienia per klient między 2012 a 2013 (growth rate).
-- nie zrobilem


-- Liczba klientów, którzy zrobili ponowne zamówienie w ciągu 30 dni od poprzedniego.
with cte as (
select customerid,orderdate,lag(orderdate) over(partition by customerid order by orderdate) as priorDay
from sales.salesorderheader
),
cte2 as (
select customerid,orderdate,priorday,round(extract(epoch from orderdate-priorday)/86400,2) as daydiff
from cte
)
select count(distinct customerid) from cte2
where daydiff <= 30;

-- Wartość sprzedaży online vs. offline (sprawdzenie kolumny OnlineOrderFlag).
select onlineorderflag,sum(subtotal) from sales.salesorderheader
group by onlineorderflag;
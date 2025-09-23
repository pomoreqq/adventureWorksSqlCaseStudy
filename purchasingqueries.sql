-- 📊 Purchasing Case Study – Zadania
-- 🔹 Łatwe (5) – proste filtry i agregacje

-- Lista wszystkich dostawców (Vendor) z ich CreditRating i statusem (ActiveFlag, PreferredVendorStatus).
select * from purchasing.vendor;
select name,creditrating,activeflag,preferredvendorstatus from purchasing.vendor
-- Liczba aktywnych dostawców (ActiveFlag = 1).
select * from purchasing.vendor
where activeflag = true;
-- Rozkład statusów (Status) w PurchaseOrderHeader – ile zamówień ma każdy status.
select status,count(*) as orderCount from purchasing.purchaseorderheader
group by status;
-- Najczęściej zamawiane produkty (TOP 10 wg SUM(OrderQty) w PurchaseOrderDetail).
select productid,sum(orderqty) as totalsum from purchasing.purchaseorderdetail
group by productid
order by totalsum desc
limit 10
-- Łączna liczba zamówień (PurchaseOrderHeader) per rok (OrderDate).
select extract(year from orderdate) as yr,count(*) from purchasing.purchaseorderheader
group by yr
-- 🔸 Średnie (10) – joiny, daty, pivoty, dodatkowa logika

-- Średni czas realizacji zamówienia per dostawca: AVG(ShipDate – OrderDate) (tylko gdy obie daty są niepuste).
select vendorid,extract(epoch from avg(shipdate-orderdate))/86400 as avgOrder from purchasing.purchaseorderheader
where shipdate is not null and orderdate is not null
group by vendorid
order by avgorder
-- Łączna wartość zamówień (SUM(OrderQty * UnitPrice)) per dostawca (JOIN Header + Detail).
select * from purchasing.purchaseorderheader
select poh.vendorid,sum(pod.orderqty * pod.unitprice) as totalSum from purchasing.purchaseorderdetail pod
inner join purchasing.purchaseorderheader poh
on poh.purchaseorderid = pod.purchaseorderid
group by poh.vendorid
order by totalsum desc
-- Największe pojedyncze zamówienie wartościowo w każdym roku (JOIN + okno/podzapytnie).
with cte as (
select extract(year from orderdate) as yr,purchaseorderid,subtotal from purchasing.purchaseorderheader
group by yr,purchaseorderid
order by yr,subtotal desc
),
cte2 as (
select yr,purchaseorderid,subtotal,row_number() over(partition by yr order by subtotal desc) as rownumber from cte
)
select * from cte2
where rownumber = 1;

-- TOP 5 produktów z największym kosztem zakupu w historii.
select productid,sum(orderqty*unitprice) as sumTotal from purchasing.purchaseorderdetail
group by productid
order by sumtotal desc
limit 5
-- Średnia liczba pozycji w zamówieniu (COUNT(detail)/COUNT(header)) per rok.
select extract(year from poh.orderdate) as yr, count(pod.purchaseorderdetailid)::numeric/count(distinct pod.purchaseorderid) as ratio from purchasing.purchaseorderheader poh
inner join purchasing.purchaseorderdetail pod
on pod.purchaseorderid = poh.purchaseorderid
group by yr

-- Liczba dostawców przypisanych do każdej kategorii (ProductVendor → Product → Subcategory → Category).
select pc.name,count(distinct pv.businessentityid) from purchasing.productvendor pv
inner join production.product p
on p.productid = pv.productid
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
inner join production.productcategory pc
on pc.productcategoryid = psc.productcategoryid
group by pc.name
-- Porównanie średniej ceny zakupu produktu (PurchaseOrderDetail) z jego StandardCost.
with cte as (
select productid,round(avg(unitprice),2) as avgpricefromdetail from purchasing.purchaseorderdetail
group by productid
order by productid
),
cte2 as (select productid,round(avg(standardprice),2) as avgStandardFromVendor from purchasing.productvendor
group by productid
)
select cte.productid,cte.avgpricefromdetail,cte2.avgStandardFromVendor,
case
	when cte.avgpricefromdetail > cte2.avgstandardfromvendor then 1
	else 0 
end as isAvgMoreThanStandard
from cte
left join cte2
on cte.productid = cte2.productid
-- Analiza sezonowości: łączna wartość zakupów per miesiąc (trend czasowy).
select extract(year from orderdate) as yr,extract(month from orderdate) as mnth,sum(subtotal) from purchasing.purchaseorderheader
group by yr,mnth
order by yr,mnth
-- Pivot: rozkład statusów zamówień (Status) per rok – wiersze = rok, kolumny = statusy, wartości = liczba zamówień.
SELECT
    EXTRACT(YEAR FROM OrderDate) AS yr,
    COUNT(*) FILTER (WHERE Statusshipmethodid = 1) AS status_1,
    COUNT(*) FILTER (WHERE Status = 2) AS status_2,
    COUNT(*) FILTER (WHERE Status = 3) AS status_3,
    COUNT(*) FILTER (WHERE Status = 4) AS status_4
FROM purchasing.PurchaseOrderHeader
GROUP BY yr
ORDER BY yr;
-- Pivot: udział metod dostawy (ShipMethod) per rok – wiersze = rok, kolumny = ShipMethod, wartości = % zamówień.
select * from purchasing.purchaseorderheader
select distinct shipmethodid from purchasing.purchaseorderheader

with cte as (
select extract(year from orderdate) as yr,
	COUNT(*) FILTER (WHERE shipmethodid = 1) AS ship_1,
    COUNT(*) FILTER (WHERE shipmethodid = 2) AS ship_2,
    COUNT(*) FILTER (WHERE shipmethodid = 3) AS ship_3,
    COUNT(*) FILTER (WHERE shipmethodid = 4) AS ship_4,
	COUNT(*) FILTER (WHERE shipmethodid = 5) AS ship_5,
count(*) as totalcount
from purchasing.purchaseorderheader
group by yr
order by yr
)
select yr,ship_1::numeric/totalcount * 100 as shipratio1,
ship_2::numeric/totalcount * 100 as shipratio2,
ship_3::numeric/totalcount * 100 as shipratio3,
ship_4::numeric/totalcount * 100 as shipratio4,
ship_5::numeric/totalcount * 100 as shipratio5
from cte

-- 🔺 Trudne (10) – okna, Pareto, analizy ryzyka, zaawansowane pivoty

-- Dostawcy, którzy dostarczają >10 różnych produktów (JOIN ProductVendor, COUNT(DISTINCT ProductID)).
select v.name,count(distinct pv.productid) as uniqueproductcount from purchasing.productvendor pv
inner join purchasing.vendor v
on v.businessentityid = pv.businessentityid
group by v.name
having count(distinct pv.productid) > 10
order by  uniqueproductcount desc
-- Dla każdego dostawcy policz udział wartościowy w całości zakupów (% udział w SUMA wszystkich zamówień).
with cte as (
select vendorid,sum(subtotal) as sumperv from purchasing.purchaseorderheader
group by vendorid
),
cte2 as (
select vendorid,sumperv,(select sum(subtotal) from purchasing.purchaseorderheader) as totalsum from cte
) 
select v.name,round(sumperv/totalsum * 100,2) as percentageoftotal from cte2
left join purchasing.vendor v
on cte2.vendorid = v.businessentityid
order by percentageoftotal desc
-- Produkty kupowane od więcej niż jednego dostawcy.
select productid,count(distinct businessentityid) from purchasing.productvendor
group by productid
having count(distinct businessentityid) > 1;
-- Zmiana średniej ceny zakupu produktu w czasie: różnica między pierwszym a ostatnim okresem (FIRST_VALUE / LAST_VALUE).
-- nie da sie
-- Analiza Pareto: 20% dostawców odpowiada za 80% wartości zakupów (okna + cumsum).
-- done wczesniej
-- Średni lead time (AverageLeadTime z ProductVendor) per kategoria produktu.
select pc.name,avg(pv.averageleadtime) as days from purchasing.productvendor pv
inner join production.product p
on pv.productid = p.productid
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
inner join production.productcategory pc
on pc.productcategoryid = psc.productcategoryid
group by pc.name
-- Identyfikacja zamówień, gdzie ReceivedQty < OrderQty (niedostawy) i ich odsetek w całości zamówień.
with cte as (
select count(*) as notenoughcount from purchasing.purchaseorderdetail
where orderqty > receivedqty
)
select notenoughcount::numeric/(select count(*) from purchasing.purchaseorderdetail) from cte
-- Różnorodność portfela: dla każdego dostawcy liczba różnych podkategorii produktów.
select pv.businessentityid,count(distinct psc.productsubcategoryid) from purchasing.productvendor pv
inner join production.product p
on pv.productid = p.productid
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
group by pv.businessentityid
-- Analiza ryzyka: dostawcy, którzy są jedynymi dostawcami w swojej kategorii (monopol).
select pc.name,count(distinct pv.businessentityid) from purchasing.productvendor pv
inner join production.product p
on pv.productid = p.productid
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
inner join production.productcategory pc
on pc.productcategoryid = psc.productcategoryid
group by pc.name
-- Pivot: suma wartości zamówień per dostawca i rok – wiersze = dostawcy, kolumny = lata, wartości = suma (ORDER BY suma całości malejąco).
select distinct extract(year from orderdate) from purchasing.purchaseorderheader
-- 2013
-- 2011
-- 2014
-- 2012
select vendorid,
sum(subtotal) filter (where extract(year from orderdate) = 2011) as date2011,
sum(subtotal) filter (where extract(year from orderdate) = 2012) as date2012,
sum(subtotal) filter (where extract(year from orderdate) = 2013) as date2013,
sum(subtotal) filter (where extract(year from orderdate) = 2014) as date2014,
sum(subtotal) as totalSum
from purchasing.purchaseorderheader
group by vendorid
order by totalsum desc
order by

-- 🟡 5 średnich

-- Średnia i mediana wartości zamówienia (SubTotal) per rok.
select extract(year from orderdate) as yr,avg(subtotal),percentile_cont(0.5)
within group ( order by subtotal) as mediansubtotal
from purchasing.purchaseorderheader
group by yr
-- Top 3 produkty z największą liczbą dostawców (ProductVendor) w każdej podkategorii (ProductSubcategory).
with cte as (
select psc.name,pv.productid,count(distinct pv.businessentityid ) from purchasing.productvendor pv
inner join production.product p
on p.productid = pv.productid
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
group by psc.name,pv.productid
),
cte2 as (
select *,row_number() over(partition by name order by count desc) as rownmbr from cte
)
select * from cte2
where rownmbr <= 3;

-- Średni lead time per dostawca – ale tylko dla tych, którzy dostarczają co najmniej 5 różnych produktów.
with cte as (
select businessentityid,count(distinct productid) as prodcount from purchasing.productvendor
group by businessentityid
having count(distinct productid) > 5
)
select cte.businessentityid,avg(pv.averageleadtime) as avgleadtime from cte
left join purchasing.productvendor pv
on cte.businessentityid = pv.businessentityid
where pv.businessentityid is not null
group by cte.businessentityid
order by avgleadtime
-- Procent zamówień z opóźnioną dostawą (ShipDate > DueDate) per rok.
-- niemozliwe do wykonania
-- Łączna wartość zamówień per status (PurchaseOrderHeader.Status) i udział % w całkowitej wartości.
with cte as (
select status,sum(subtotal) as sumperstatus from purchasing.purchaseorderheader
group by status
)
select status,sumperstatus,sumperstatus/(select sum(subtotal) from purchasing.purchaseorderheader) * 100 as percentagepersstatusintotal from cte;
-- 🔴 10 trudnych

-- Ranking dostawców wg średniego udziału w zamówieniach w czasie → oblicz udział wartościowy per rok, a następnie ranking vendorów w każdym roku.
with cte as (
select extract(year from orderdate) as yr, vendorid,sum(subtotal) as subtotalinyearpervendor from purchasing.purchaseorderheader
group by yr,vendorid
),
cte2 as (select extract(year from orderdate) as yr,sum(subtotal) as subtotalperyear from purchasing.purchaseorderheader group by yr),
cte3 as (
select cte.yr,cte.vendorid,cte.subtotalinyearpervendor,cte2.subtotalperyear,round(cte.subtotalinyearpervendor::numeric/cte2.subtotalperyear * 100,2) as percentageofsubtotalperyear from cte
left join cte2
on cte.yr = cte2.yr
order by cte.yr,cte.subtotalinyearpervendor desc
),
cte4 as (
select yr,vendorid,percentageofsubtotalperyear,row_number() over(partition by yr order by percentageofsubtotalperyear desc) as vendorrank from cte3
)
select v.name,avg(vendorrank) as avgvendorrank from cte4
left join purchasing.vendor v
on v.businessentityid = cte4.vendorid
group by v.name
order by avgvendorrank

-- Wykrywanie anomalii cenowych: produkty, gdzie UnitPrice w zamówieniu jest wyższe niż średnia cena z ProductVendor.StandardPrice o > 2 odchylenia standardowe.
with cte as (
select productid,avg(standardprice) as avgstandardprice, stddev_samp(standardprice) as stdstandardprice from purchasing.productvendor
group by productid
),
cte2 as (
select productid,avgstandardprice,coalesce(stdstandardprice,0) as stdstandardpricecoalesce from cte
)
select pod.purchaseorderid,pod.productid,pod.unitprice,cte2.avgstandardprice,cte2.stdstandardpricecoalesce from purchasing.purchaseorderdetail pod
inner join cte2
on cte2.productid = pod.productid
where pod.unitprice > cte2.avgstandardprice + 2 * cte2.stdstandardpricecoalesce and  cte2.stdstandardpricecoalesce > 0
-- Pivot: udział % wartości zamówień (SubTotal) per status w podziale na lata – wiersze = lata, kolumny = statusy, wartości = procent wartości.
with cte as (
select extract(year from orderdate  ) as yr,
	sum(subtotal) filter (where status = 1) as status1,
	sum(subtotal) filter (where status = 2) as status2,
	sum(subtotal) filter (where status = 3) as status3,
	sum(subtotal) filter (where status =  4) as status4,
sum(subtotal) as totalsum
from purchasing.purchaseorderheader
group by  yr
)
select yr,round(status1/totalsum * 100,2) as status1percentageperyear,round(status2/totalsum * 100,2)as status2percentageperyea,
round(status3/totalsum * 100,2)as status3percentageperyea,round(status4/totalsum * 100,2)as status4percentageperyea
from cte
-- Wielkość zamówień per dostawca: kwartyle (NTILE(4)) wg wartości zamówień, sprawdź rozkład dostawców w kwartylach.
with cte as (
select vendorid,subtotal,ntile(4) over(order by subtotal desc ) as quartile from purchasing.purchaseorderheader
),
cte2 as (
select vendorid,count(*) as ordercount from purchasing.purchaseorderheader
group by vendorid
),
cte3 as (
select vendorid,
	count(*) filter(where quartile = 1) as Q1,
	count(*) filter(where quartile = 2) as Q2,
	count(*) filter(where quartile = 3) as Q3,
	count(*) filter(where quartile = 4) as Q4
from cte 
group by vendorid
)
select cte3.vendorid,cte3.q1,cte3.q2,cte3.q3,cte3.q4,cte2.ordercount from cte3
left join cte2
on cte3.vendorid = cte2.vendorid
-- Vendor concentration: dla każdej kategorii produktów policz udział największego dostawcy w wartości zamówień (np. vendor A odpowiada za 60% zamówień w kategorii „Components”).
with cte as (
select c.name as cname,v.name,sum(pod.unitprice * pod.orderqty) as subtotalSumForCategoryPerVendor from purchasing.purchaseorderdetail pod
inner join production.product p
on pod.productid = p.productid
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
inner join production.productcategory c
on c.productcategoryid = psc.productcategoryid
inner join purchasing.purchaseorderheader poh
on poh.purchaseorderid = pod.purchaseorderid
inner join purchasing.vendor v
on poh.vendorid = v.businessentityid
group by c.name,v.name
order by c.name,subtotalSumForCategoryPerVendor desc
),
cte2 as (
select c.name,sum(pod.unitprice * pod.orderqty) as subtotalSumForCategory from purchasing.purchaseorderdetail pod
inner join production.product p
on pod.productid = p.productid
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
inner join production.productcategory c
on c.productcategoryid = psc.productcategoryid
group by c.name
),
cte3 as (
select cte.cname,cte.name,round(cte.subtotalSumForCategoryPerVendor/cte2.subtotalsumforcategory,2),row_number()
over(partition by cte.cname order by cte.subtotalSumForCategoryPerVendor desc ) as ranknmbr
from cte
left join cte2
on cte.cname = cte2.name
)
select * from cte3 where ranknmbr = 1;
-- Pierwsza i ostatnia data współpracy z każdym dostawcą (min i max OrderDate), oraz różnica w latach – ile lat trwa współpraca.
with cte as (
select vendorid,min(orderdate)as mindate,max(orderdate)as maxdate from purchasing.purchaseorderheader
group by vendorid
)
select vendorid,mindate,maxdate,extract(epoch from maxdate-mindate)/86400 as daystogether from cte
order by daystogether desc
-- Średnia cena zakupu w czasie: oblicz średnią UnitPrice produktu per rok, a następnie policz % zmiany rok do roku.
with cte as (
select extract(year from poh.orderdate) as yr,pod.productid,avg(pod.unitprice) as avgunitprice from purchasing.purchaseorderdetail pod
inner join purchasing.purchaseorderheader poh
on poh.purchaseorderid = pod.purchaseorderid
group by pod.productid,yr
order by productid,yr
),
cte2 as (
select productid,yr,avgunitprice,lag(avgunitprice) over(partition by productid order by yr) as prioryravgunitprice from cte
)
select productid,avgunitprice,prioryravgunitprice,((avgunitprice-prioryravgunitprice)/prioryravgunitprice)*100::numeric  as yoy from cte2
where prioryravgunitprice is not null
-- Produkty z nieciągłością dostawców: znajdź produkty, które w danym roku miały co najmniej jednego dostawcę, a w kolejnym roku nie miały żadnego (LEFT JOIN na lata).
select extract(year from poh.orderdate) as yr,pod.productid,count(distinct poh.vendorid) from purchasing.purchaseorderdetail pod
inner join purchasing.purchaseorderheader poh
on poh.purchaseorderid = pod.purchaseorderid
group by yr,pod.productid
having count(distinct poh.vendorid) = 0
-- Ranking stabilności cen: policz odchylenie standardowe UnitPrice per produkt; top 10 produktów o najmniejszej zmienności (stabilne ceny).
select productid,stddev_samp(unitprice) from purchasing.purchaseorderdetail 
group by productid
having stddev_samp(unitprice) > 0
order by stddev_samp(unitprice)
limit 10

-- Koszt opóźnień: wartość zamówień (SubTotal), które zostały wysłane po DueDate – per vendor i rok; ranking vendorów wg największego łącznego kosztu opóźnień.
-- niewykonalne
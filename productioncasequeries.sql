-- 📦 AdventureWorks – Production Case Study (25 pytań)
-- 🟢 Łatwe (5)

-- Ile jest produktów w każdej kategorii (ProductCategory)?
select pc.name,count(p.productid) from production.product p
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
inner join production.productcategory pc
on pc.productcategoryid = psc.productcategoryid
group by pc.name;
-- Średnia lista cen (ListPrice) produktów w każdej podkategorii.
with cte as (
select productsubcategoryid, avg(listprice) as avgprice from production.product
where listprice > 0
group by productsubcategoryid
)
select cte.productsubcategoryid,psc.name,cte.avgprice from cte
left join production.productsubcategory psc
on psc.productsubcategoryid = cte.productsubcategoryid
order by cte.avgprice desc
-- Ile produktów ma status „discontinued” (zerowy SellEndDate)?
select count(*)from production.product
where sellenddate is not null;
-- Liczba produktów w stanie „Finished Goods” vs „Components”.
SELECT 
    FinishedGoodsFlag,
    COUNT(*) AS product_count
FROM Production.Product
GROUP BY FinishedGoodsFlag;
-- Najtańszy i najdroższy produkt w każdej kategorii.
select pc.name,min(p.listprice) as minPrice,max(p.listprice) as maxPrice from production.product p
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
inner join production.productcategory pc
on pc.productcategoryid = psc.productcategoryid
group by pc.name;
-- 🟡 Średnie (10)

-- Historia zmian kosztów (ProductCostHistory) – średni koszt standardowy produktu w czasie.
select * from production.product
select * from production.productcosthistory;
select productid,standardcost,avg(standardcost) over(partition by productid order by startdate) as avgPriceInTime from production.productcosthistory
-- Produkty, które zmieniły koszt więcej niż 3 razy.
select productid,count(*) from production.productcosthistory
group by productid
having count(*) > 3;
-- Średni czas obowiązywania kosztu standardowego (EndDate - StartDate).
select productid,extract(epoch from avg(enddate-startdate)) / 86400 as datediff from production.productcosthistory
group by productid;
-- Średni ListPrice produktów wg koloru (np. Red, Black, Silver).
select color,avg(listprice) as avglistprice from production.product
where color is not null and listprice > 0
group by color

select * from production.product
where finishedgoodsflag = false and color is not null;
-- Najczęściej używane komponenty w BillOfMaterials (ile razy występują jako ComponentID).
select componentid,count(*) from production.billofmaterials
group by componentid
order by count(*) desc
-- Produkty, które są używane jako komponent w innych produktach i jednocześnie są sprzedawane jako gotowe (FinishedGoodsFlag = 1).
with cte as (
select productid,name from production.product
where finishedgoodsflag = True
),
cte2 as (
select cte.productid,cte.name,boi.componentid from cte
left join production.billofmaterials boi
on cte.productid = boi.componentid
where boi.componentid is not null
)
select distinct productid,name from cte2 
-- Średnia liczba komponentów na produkt złożony (BillOfMaterials).
with cte as (
select productassemblyid,count(componentid) as componentCount from production.billofmaterials
where productassemblyid is not null
group by productassemblyid
)
select avg(componentcount) from cte;
-- Produkty, które mają więcej niż 2 poziomy BOM (komponent w komponencie).
SELECT DISTINCT bom1.ProductAssemblyID AS top_product,
       bom1.ComponentID AS mid_component,
       bom2.ComponentID AS low_component
FROM Production.BillOfMaterials bom1
INNER JOIN Production.BillOfMaterials bom2
    ON bom1.ComponentID = bom2.ProductAssemblyID
WHERE bom1.ComponentID <> bom2.ProductAssemblyID;
-- Produkty z największym zapasem (ProductInventory) w każdym magazynie (LocationID).
select * from production.productinventory;
with cte as (
select locationid,productid,sum(quantity) as productSum from production.productinventory
group by locationid,productid
order by locationid
),
 cte2 as (
select locationid,productid,productSum,row_number() over(partition by locationid order by productsum desc) as rowrank
from cte
)
select pl.name,p.name,productsum,rowrank from cte2
left join production.location pl
on pl.locationid=cte2.locationid
left join production.product p
on p.productid=cte2.productid
where rowrank=1
-- Średnia ilość (Quantity) w magazynie per produkt i per lokalizacja.
select locationid,productid,avg(quantity) as avgquantity from production.productinventory
group by locationid,productid
order by locationid,productid
-- 🔴 Trudne (10)

-- Produkty, których zapas spadał kolejno przez 3 miesiące (trend spadkowy w ProductInventory).
select * from production.productinventory; -- nie da sie
-- Produkty, które nigdy nie miały zapasu w żadnej lokalizacji (martwe rekordy w katalogu).
select p.productid,pi.productid from production.product p
left join production.productinventory pi
on p.productid = pi.productid
where pi.productid is null
-- Produkty z największą różnicą między średnią ceną sprzedaży (ListPrice) a średnim kosztem standardowym (marża).
with cte as (
select productid,avg(listprice) as avglistprice from production.productlistpricehistory
group by productid
),
 cte2 as (
select productid,avg(standardcost) as avgstandardcost from production.productcosthistory
group by productid
 )
 select cte.productid,round((avglistprice - avgstandardcost) / avglistprice * 100
,5) as marza from cte
 inner join cte2
 on cte.productid = cte2.productid
-- Złożone BOM – liczba wszystkich komponentów potrzebnych do wyprodukowania roweru (rekurencja / self join na BOM).
-- nie wiem
-- Produkty, które pojawiły się w katalogu (Product table) w 2008 roku i do dziś mają aktywny SellEndDate.
select name,extract(year from sellstartdate) as yr from production.product
where sellenddate is null and extract(year from sellstartdate) in (2008) ;
-- Porównanie średnich kosztów produkcji między kategoriami – które kategorie są najdroższe w produkcji.
with cte as (
select productsubcategoryid,avg(standardcost) as avgstandardcost from production.product
where standardcost > 0
group by productsubcategoryid
)
select pc.name,avg(avgstandardcost) as categoryAvg from cte
left join production.productsubcategory psc
on psc.productsubcategoryid = cte.productsubcategoryid
left join production.productcategory pc
on pc.productcategoryid = psc.productcategoryid
group by pc.name
-- Identyfikacja komponentów, które występują w BOM wielu różnych produktów (cross-sell na produkcji).
SELECT 
    b.ComponentID,
    p.Name AS ComponentName,
    COUNT(DISTINCT b.ProductAssemblyID) AS UsedInProducts
FROM Production.BillOfMaterials b
INNER JOIN Production.Product p
    ON b.ComponentID = p.ProductID
WHERE b.ProductAssemblyID IS NOT NULL   -- tylko dla produktów nadrzędnych
GROUP BY b.ComponentID, p.Name
HAVING COUNT(DISTINCT b.ProductAssemblyID) > 1
ORDER BY UsedInProducts DESC
-- Dla każdego produktu policz, ile lokalizacji magazynowych przechowuje jego zapasy (ile różnych LocationID).
with cte as (
select p.productid,pi.locationid,sum(pi.quantity) as sumquantity from production.product p
inner join production.productinventory pi
on pi.productid = p.productid
group by p.productid,pi.locationid
)
select productid,count(distinct locationid) as uniquelocationcount,sum(sumquantity) as totalsum from cte
group by productid
-- Produkty, które miały co najmniej jedną przerwę w obowiązywaniu StandardCost (dziury w ProductCostHistory).
with cte as (
 select productid,startdate,lag(enddate) over(partition by productid order by startdate) as priorenddate from production.productcosthistory
)
select productid from cte
where startdate > priorenddate + interval '1 day'
-- Analiza Pareto: które 20% produktów odpowiada za 80% wartości zapasu (ilość * standard cost).
with cte as (
select p.productid,sum(pi.quantity * p.standardcost) as inventoryValue from production.product p
inner join production.productinventory pi 
on p.productid = pi.productid
where p.standardcost > 0
group by p.productid
),
cte2 as (
select productid,(select sum(p.standardcost * pi.quantity) from production.product p inner join production.productinventory pi on pi.productid=p.productid) as totalValue,
inventoryvalue from cte
),
cte3 as (
select productid,totalvalue,inventoryvalue,round(inventoryvalue/totalvalue,5) as percentagein from cte2
order by inventoryvalue desc
),
cte4 as (
select productid,sum(percentagein) over(order by percentagein desc) as cumsum from cte3
),
cte5 as (
select cte4.productid,p.name from cte4
left join production.product p
on cte4.productid = p.productid
where cte4.cumsum <= 0.8 -- 85 produktow
),
cte6 as (
select count(distinct productid) as paretoproductcount,(select count(distinct productid) from production.product where standardcost > 0) as totalcount from cte5
)
select  1.0 *paretoproductcount/totalcount from cte6; -- 0.27
-- 🟡 Średnie (10)

-- Medianowy ListPrice w każdej podkategorii (tylko ListPrice>0).
-- Tabele: Product, ProductSubcategory.
select psc.name,percentile_cont(0.5) within group (order by p.listprice) as medianAmount from production.product p
inner join production.productsubcategory psc
on psc.productsubcategoryid = p.productsubcategoryid
where p.listprice > 0
group by psc.name
-- Produkty, które są sprzedawane (FinishedGoodsFlag=1) i jednocześnie występują jako komponent w BOM.
-- Tabele: Product, BillOfMaterials (po ComponentID).
select p.productid,p.name from production.product p
inner join production.billofmaterials b
on p.productid = b.componentid
where finishedgoodsflag = true
-- Najczęściej używane komponenty w BOM (top N po liczbie wystąpień jako ComponentID).
-- Tabela: BillOfMaterials.
select * from production.billofmaterials
select componentid,count(productassemblyid) from production.billofmaterials
where productassemblyid is not null
group by componentid
order by count(productassemblyid) desc ;
-- Średnia liczba komponentów na produkt złożony (uwzględnij PerAssemblyQty jako wagi).
-- Tabela: BillOfMaterials.
with cte as (
select productassemblyid,sum(perassemblyqty) as sumperproduct from production.billofmaterials
group by productassemblyid

)
select avg(sumperproduct) from cte;






-- Zmiana kosztu: dla każdego produktu różnica i % zmiany między pierwszym a ostatnim StandardCost.
-- Tabela: ProductCostHistory.
with cte as (
select productid,standardcost,first_value(standardcost) over(partition by productid order by startdate) as firstvalue,last_value(standardcost)
over(partition by productid) as lastvalue,row_number() over(partition by productid) as rownmbr from production.productcosthistory
)
select productid, firstvalue-lastvalue as valuediff,100 - (firstvalue/lastvalue) * 100 as percentagediff from cte
where rownmbr = 1;
-- Zmiany cen katalogowych: liczba zmian ListPrice per produkt i podkategoria; top podkategorie o największej „zmienności”.
-- Tabele: ProductListPriceHistory, Product, ProductSubcategory.
with cte as (
select productid,count(*) as changecount from production.productlistpricehistory
group by productid
),
 cte2 as (
select p.productsubcategoryid,sum(changecount) as sumOfChanges from cte
left join production.product p
on cte.productid = p.productid
group by productsubcategoryid
)
select psc.name,sumOfChanges from cte2
left join production.productsubcategory psc
on cte2.productsubcategoryid = psc.productsubcategoryid
order by sumofchanges desc

-- 🔴 Trudne (10)

-- Czas cyklu zlecenia: średni czas od StartDate do EndDate w WorkOrder per produkt; top/bottom produkty.
-- Tabela: WorkOrder.
select productid,extract(epoch from avg(enddate-startdate))/86400 as numberofdays from production.workorder
group by productid
order by numberofdays desc;
-- Opóźnienia operacji: w WorkOrderRouting policz średnie opóźnienie ActualStartDate - ScheduledStartDate per LocationID (work center) i odsetek spóźnionych operacji.
-- Tabela: WorkOrderRouting.
select locationid,extract(epoch from avg(actualstartdate-scheduledstartdate))/86400 as numberofdays from production.workorderrouting
group by locationid

select 1.0 * count(*)/(select count(*) from production.workorderrouting) * 100 from production.workorderrouting
where actualstartdate > scheduledstartdate 

SELECT 
    locationid,
    ROUND(EXTRACT(EPOCH FROM AVG(actualstartdate - scheduledstartdate)) / 86400, 2) AS avg_delay_days,
    ROUND(100.0 * SUM(CASE WHEN actualstartdate > scheduledstartdate THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_ops_percent
FROM production.workorderrouting
GROUP BY locationid
ORDER BY avg_delay_days DESC;
-- Przepustowość work center: łączne ActualResourceHrs per LocationID i rok; ranking przepustowości.
-- Tabela: WorkOrderRouting.
with cte as (
select locationid,extract(year from actualstartdate) as yr,sum((actualresourcehrs*24)/365) as sumResourceYear from production.workorderrouting
group by locationid,yr
)
select locationid,yr,sumresourceyear,rank() over(order by sumresourceyear desc) from cte;
-- Scrap rate: średni udział ScrappedQty / OrderQty per produkt i powód (ScrapReason), z rankingiem najgorszych.
-- Tabele: WorkOrder, ScrapReason
with cte as (
select productid,scrapreasonid,sum(scrappedqty) as sumscrapped,sum(orderqty) as sumqty from production.workorder
where scrappedqty > 0 and scrapreasonid is not null
group by productid,scrapreasonid
),
cte2 as (
select productid,scrapreasonid,round(sumscrapped::numeric/sumqty,4) * 100 as percentageScrap from cte
)
select scr.name,avg(percentagescrap) as avgscrap from cte2
left join production.scrapreason scr
on scr.scrapreasonid = cte2.scrapreasonid
group by scr.name
order by avgscrap desc

select scr.name,sum(wo.scrappedqty::numeric)/sum(wo.orderqty) * 100 as scraprate from production.workorder wo
inner join production.scrapreason scr
on scr.scrapreasonid = wo.scrapreasonid
group by scr.name
-- Yield produkcyjny: średni współczynnik (OrderQty - ScrappedQty) / OrderQty per kategoria produktu.
-- Tabele: WorkOrder, Product, ProductSubcategory, ProductCategory.
with cte as (
select productid,sum(orderqty - scrappedqty)::numeric / sum(orderqty) as metric from production.workorder 
group by productid
)
select pc.name,avg(cte.metric) from cte
left join production.product p
on cte.productid = p.productid
left join production.productsubcategory psc 
on psc.productsubcategoryid = p.productsubcategoryid
left join production.productcategory pc
on pc.productcategoryid = psc.productcategoryid
group by pc.name
-- Ruchy magazynowe: w TransactionHistory policz roczny bilans ilości per produkt i typ transakcji; wskaż produkty z ujemnym bilansem.
-- Tabela: TransactionHistory.
select extract(year from transactiondate) as yr,productid,transactiontype,sum(quantity) from production.transactionhistory
group by yr,productid,transactiontype
having sum(quantity) < 0

-- nie ma takiego produtku
-- Ryzyko ujemnej marży: produkty, dla których średni ListPrice ≤ średni StandardCost (na historii).
-- Tabele: ProductListPriceHistory, ProductCostHistory.
with cte as(
select productid,avg(listprice) as avglistprice from production.productlistpricehistory
group by productid
),
 cte2 as(
select productid,avg(standardcost) as avgstandardcost from production.productcosthistory
group by productid
)
select cte.productid,cte.avglistprice,cte2.avgstandardcost from cte
left join cte2
on cte.productid = cte2.productid
where cte.avglistprice < cte2.avgstandardcost

-- nie ma takiego produktu
-- Zmienność cen: odchylenie standardowe ListPrice w czasie per podkategoria; ranking najbardziej „chwiejnych” podkategorii.
-- Tabele: ProductListPriceHistory, ProductSubcategory.
with cte as (select productid,stddev_samp(listprice) as stddev,count(*) as changesCount from production.productlistpricehistory
where listprice is not null
group by productid
having count(*) > 1)
select psc.name,stddev_samp(cte.stddev) from cte
left join production.product p
on cte.productid = p.productid
left join production.productsubcategory psc
on p.productsubcategoryid = psc.productsubcategoryid
group by psc.name
having stddev_samp(cte.stddev) > 0
order by stddev_samp(cte.stddev) desc
-- Niespójności jednostek miary: komponenty, które w BOM pojawiają się z więcej niż jedną UnitMeasureCode.
-- Tabele: BillOfMaterials, UnitMeasure.
select componentid,count(distinct unitmeasurecode) from production.billofmaterials
group by componentid
having count(distinct unitmeasurecode) > 1


-- —
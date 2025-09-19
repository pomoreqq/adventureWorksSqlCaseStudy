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

-- Produkty, które pojawiły się w katalogu (Product table) w 2008 roku i do dziś mają aktywny SellEndDate.

-- Porównanie średnich kosztów produkcji między kategoriami – które kategorie są najdroższe w produkcji.

-- Identyfikacja komponentów, które występują w BOM wielu różnych produktów (cross-sell na produkcji).

-- Dla każdego produktu policz, ile lokalizacji magazynowych przechowuje jego zapasy (ile różnych LocationID).

-- Produkty, które miały co najmniej jedną przerwę w obowiązywaniu StandardCost (dziury w ProductCostHistory).

-- Analiza Pareto: które 20% produktów odpowiada za 80% wartości zapasu (ilość * standard cost).
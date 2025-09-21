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

-- Liczba dostawców przypisanych do każdej kategorii (ProductVendor → Product → Subcategory → Category).

-- Porównanie średniej ceny zakupu produktu (PurchaseOrderDetail) z jego StandardCost.

-- Analiza sezonowości: łączna wartość zakupów per miesiąc (trend czasowy).

-- Pivot: rozkład statusów zamówień (Status) per rok – wiersze = rok, kolumny = statusy, wartości = liczba zamówień.

-- Pivot: udział metod dostawy (ShipMethod) per rok – wiersze = rok, kolumny = ShipMethod, wartości = % zamówień.

-- 🔺 Trudne (10) – okna, Pareto, analizy ryzyka, zaawansowane pivoty

-- Dostawcy, którzy dostarczają >10 różnych produktów (JOIN ProductVendor, COUNT(DISTINCT ProductID)).

-- Dla każdego dostawcy policz udział wartościowy w całości zakupów (% udział w SUMA wszystkich zamówień).

-- Produkty kupowane od więcej niż jednego dostawcy.

-- Zmiana średniej ceny zakupu produktu w czasie: różnica między pierwszym a ostatnim okresem (FIRST_VALUE / LAST_VALUE).

-- Analiza Pareto: 20% dostawców odpowiada za 80% wartości zakupów (okna + cumsum).

-- Średni lead time (AverageLeadTime z ProductVendor) per kategoria produktu.

-- Identyfikacja zamówień, gdzie ReceivedQty < OrderQty (niedostawy) i ich odsetek w całości zamówień.

-- Różnorodność portfela: dla każdego dostawcy liczba różnych podkategorii produktów.

-- Analiza ryzyka: dostawcy, którzy są jedynymi dostawcami w swojej kategorii (monopol).

-- Pivot: suma wartości zamówień per dostawca i rok – wiersze = dostawcy, kolumny = lata, wartości = suma (ORDER BY suma całości malejąco).
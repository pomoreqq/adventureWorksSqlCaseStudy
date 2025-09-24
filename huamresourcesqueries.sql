-- -- Lista wszystkich pracowników z imieniem, nazwiskiem i datą zatrudnienia (Employee + Person).
select p.firstname,p.lastname,e.hiredate from humanresources.employee e
inner join person.person p
on p.businessentityid = e.businessentityid
-- -- Policz ilu pracowników pracuje w każdym dziale (Department).
select d.name,count(distinct edh.businessentityid) from humanresources.employeedepartmenthistory edh
inner join humanresources.department d
on d.departmentid = edh.departmentid
where edh.enddate is null
group by d.name
order by count(distinct edh.businessentityid) desc
-- -- Średnie wynagrodzenie (Rate) per typ zatrudnienia (SalariedFlag).
select e.salariedflag,avg(eph.rate) as avgrate from humanresources.employee e
left join humanresources.employeepayhistory eph
on e.businessentityid = eph.businessentityid
where eph.businessentityid is not null
group by e.salariedflag
order by avgrate desc
-- -- Ilu pracowników ma nad sobą menedżera (czyli nie są najwyżej w hierarchii)?
-- nie da sie

-- -- Liczba zatrudnień w każdym roku (HireDate).
select extract(year from hiredate) as yr,count(*) as ecount from humanresources.employee
group by yr
-- -- Podział pracowników wg płci i liczba w każdej grupie (Gender).
select gender,count(*) as ecount from humanresources.employee
group by gender
-- -- Lista pracowników, którzy odeszli z firmy (czyli EndDate ≠ NULL).
select * from humanresources.employeedepartmenthistory 
where enddate is not null
-- 🟡 Średnie (10)

-- Średnia długość zatrudnienia pracowników (HireDate → EndDate lub GETDATE).
select avg(enddate-startdate) from humanresources.employeedepartmenthistory
where enddate is not null
-- Top 5 działów o największej liczbie pracowników w historii (EmployeeDepartmentHistory).
select d.name,count(distinct edh.businessentityid) from humanresources.employeedepartmenthistory edh
inner join humanresources.department d
on d.departmentid = edh.departmentid
group by d.name
order by count(distinct edh.businessentityid) desc
limit 5
-- Działy z najwyższym średnim stażem pracowników.
-- nie ma sensu
-- Różnica w średnich zarobkach (Rate) między pracownikami pełnoetatowymi (SalariedFlag=1) i godzinowymi.
-- zrobione wczesniej
-- Średnia liczba pracowników przypadająca na menedżera (self-join na ManagerID).
--
-- W których latach firma zatrudniała najwięcej ludzi (liczba nowych hire).
--
-- Liczba awansów – ilu pracowników zmieniło dział w trakcie kariery (DepartmentHistory).
select businessentityid,count(distinct departmentid) as depcount from humanresources.employeedepartmenthistory
group by businessentityid
having count(distinct departmentid) > 1  -- 5 pracowinkow zmienialo dzialy
-- Lista obecnych menedżerów i liczba podwładnych.
--bezsensu
-- Medianowa długość zatrudnienia w podziale na płeć.
-- bezsensu
-- Top 3 tytuły stanowisk (JobTitle) o najwyższym średnim stażu w firmie.
-- bzesnsu tak samo
-- 🔴 Trudne (13)

-- Rekurencja: pełne drzewo hierarchii – od CEO do najniższego pracownika (rekursywny CTE po ManagerID).
-- bezsensu
-- Rekurencja: liczba poziomów podwładnych dla każdego menedżera.
-- nie da sie
-- Najdłużej istniejące zespoły (ciągłość istnienia działu z DepartmentHistory).
-- nie ma w ogole takich danych
-- Działy, które miały największą rotację pracowników (liczba wejść/wyjść).
-- nie da sie
-- Wskaźnik retencji: odsetek pracowników zatrudnionych w danym roku, którzy przetrwali > 5 lat.
-- nie da sie
-- Trend zatrudnienia kobiet vs mężczyzn rok do roku.
select extract(year from hiredate) as yr,
	count(*) filter(where gender = 'M') as malecount,
	count(*) filter (where gender = 'F') as femalecount
from humanresources.employee
group by yr
order by yr
-- Ranking menedżerów wg średniego stażu ich podwładnych.
-- nie da sie
-- Wykrywanie luk w historii zatrudnienia – pracownicy, którzy mieli przerwę między EndDate a kolejnym StartDate.
-- bezsensu
-- Średnie wynagrodzenie per dział i rok, z uwzględnieniem zmian stanowisk (Rate + DepartmentHistory).
-- za prose
-- Analiza Pareto: 20% menedżerów zarządza 80% pracowników.
-- nie da sie
-- Ścieżki awansów: top najczęściej spotykane przejścia między działami (np. Sales → Marketing).
-- nie da sie
-- Ruchy kadrowe per rok: ilu pracowników przeszło do innego działu w danym roku.
-- nie da sie
-- Analiza organizacyjna: znajdź najgłębszy poziom hierarchii (ile poziomów od CEO do najniższego szczebla).

 -- nie da sie
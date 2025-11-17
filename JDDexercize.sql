---- TEST 2 - SQL JDD ----
-- 1. Vytvoøte tabulku s názvem z_autor_vsb se stejnými atributy a primárním klíèem jako 
-- tabulka z_author (atribut rid nebude oznaèen jako identity) a dalším atributem 
-- faculty varchar(3), jehož hodnota mùže být null.
CREATE TABLE z_autor_vsb (
	zav_identity INT NOT NULL PRIMARY KEY,
	zav_name VARCHAR(200) NOT NULL,
	zav_vedidk INT ,
	zav_faculty VARCHAR(3)
);

select * from z_author
select * from z_autor_vsb

-- 2. Do tabulky z_autor_vsb vložte jedním pøíkazem insert - select všechny záznamy autorù, kteøí
-- jsou autory èlánkù, u kterých je uvedena instituce 
-- 'Vysoká škola báòská - Technická univerzita Ostrava'. 
-- Hodnotu atribut faculty nastavte explicitnì na null.
INSERT INTO z_autor_vsb
SELECT DISTINCT aut.*, null
FROM z_author aut  JOIN z_article_author aaut on aut.rid=aaut.rid
	JOIN z_article ar ON ar.aid=aaut.aid
	JOIN z_article_institution ai on ai.aid=ar.aid
	JOIN z_institution i ON i.iid=ai.iid
WHERE i.name LIKE 'Vysoká škola báòská - Technická univerzita Ostrava'

-- Napište dotaz, který vrátí poèet záznamù tabulky z_autor_vsb.
SELECT COUNT(*) AS pocetZaznamu
from z_autor_vsb

-- 3. Aktualizujte hodnotu atributu faculty tabulky z_author_vsb na hodnotu 'fei' u všech záznamù.
UPDATE z_autor_vsb 
SET zav_faculty='fei'

-- 4. Napište dotaz vracející poèet autorù z tabulky z_author_vsb, kteøí jsou z fakulty 'fei' 
-- a druhý dotaz pro poèet autorù z fakulty 'fs'.

SELECT COUNT(*)
FROM z_autor_vsb
WHERE zav_faculty LIKE 'fei'

SELECT COUNT(*)
FROM z_autor_vsb
WHERE zav_faculty LIKE 'fs'

-- 5. Do tabulky z_author_vsb pøidejte atribut department int jehož hodnota mùže být null.
ALTER TABLE z_autor_vsb
ADD department INT 

SELECT * FROM z_autor_vsb


-- 6. Aktualizujte hodnotu atributu department tabulky z_author_vsb na 460 pro autory se jmény
-- zaèínajícími na 'S'. Vypište poèet autorù z katedry 460.
UPDATE z_autor_vsb
SET department = 460
WHERE zav_name LIKE 'S%'

SELECT COUNT(*)
FROM z_autor_vsb
WHERE department = 460

-- 7. Aktualizujte hodnotu atributu department tabulky z_author_vsb na 460 pro autory se jmény
-- zaèínajícími na 'S'. Pro všechny ostatní autory nastavte hodnotu department na 470. Øešte jedním 
-- pøíkazem update.
UPDATE z_autor_vsb
SET department = CASE 
				WHEN zav_name LIKE 'S%' THEN 460
				WHEN zav_name NOT LIKE 'S%' THEN 470
				END

-- 8. Vypište poèet autorù z katedry 460 a druhým dotazem poèet autorù z katedry 470.
SELECT COUNT(*) AS pocet_autoru_z_katedry_460
FROM z_autor_vsb
WHERE department = 460

SELECT COUNT(*) AS pocet_autoru_z_katedry_470
FROM z_autor_vsb
WHERE department = 470

-- 9. Z tabulky z_author_vsb smažte všechny záznamy s katedrou 470 a dalším dotazem zjistìte
-- aktuální poèet záznamù v tabulce.
DELETE 
FROM z_autor_vsb 
WHERE department = 470

SELECT COUNT(*)
FROM z_autor_vsb

-- 10. Do tabulky z_author_vsb pøidejte atribut last_update typu date s kontrolou hodnoty pomocí
-- check >= '2025-11-11'. 
-- A pokuste se pøidat dva záznamy: jeden vyhovující podmínce a druhý
-- nevyhovující podmínce (a zapište se název integritního omezení pro check).

ALTER TABLE z_autor_vsb
ADD last_update date
	CONSTRAINT ok_last_upadet check (last_update>='2025-11-11')

INSERT INTO z_autor_vsb (zav_identity,zav_name,last_update)
	VALUES (100000,'vyhovujici podmince','2025-11-11'),
			(100001,'nevyhovujici podmince','2025-10-10')

-- 11. Zrušte integritní omezení check pro lastupdate (alter table ... drop constraint ...) a 
-- pokust se znovu  vložit neúspìšnì vložený záznam.

ALTER TABLE z_autor_vsb
DROP CONSTRAINT ok_last_upadet

INSERT INTO z_autor_vsb (zav_identity,zav_name,last_update)
	VALUES (100001,'nevyhovujici podmince','2025-10-10')

-- 12. Zrušte tabulku z_author_vsb.
DROP TABLE z_autor_vsb


--DALSI!!!!!!
--Vytvoø tabulku z_institution_copy
--stejné atributy jako z_institution
--primární klíè jako v originálu
--navíc atribut region VARCHAR(50), který mùže být NULL
--atribut iid nebude identity
CREATE TABLE z_institution_copy(
	iid int not null PRIMARY KEY,
	name varchar(1000) not null,
	reg_number varchar(20),
	street varchar(500),
	postal_code varchar(10),
	town varchar(100),
	legal_form varchar(500),
	main_goal varchar(2000),
	created datetime2(7),
	region varchar(50))

--Vlož do z_institution_copy všechny instituce z mìst obsahující „Praha“
--jedním Insert–Select
--region nastav na 'CZ'
INSERT INTO z_institution_copy 
	SELECT *,'CZ'
	FROM z_institution
	WHERE town LIKE '%Praha%'

--3) Vypiš poèet vložených institucí
SELECT COUNT(*)
FROM z_institution_copy

--4) Pøidej do tabulky atribut is_public INT NOT NULL DEFAULT(1)
ALTER TABLE z_institution_copy 
ADD is_public INT NOT NULL DEFAULT(1)

--5) Aktualizuj:
--nastav is_public = 0 pro instituce, jejichž jméno obsahuje „s.r.o.“
--ostatním nech pùvodní hodnotu
--(Jeden UPDATE.)
UPDATE  z_institution_copy 
SET is_public = 0 
WHERE name LIKE '%s.r.o.'

select*from z_institution_copy where name LIKE '%s.r.o.'

--6) Vypiš poèet „soukromých“ (is_public=0)
select COUNT(*)
from z_institution_copy 
where name LIKE '%s.r.o.'

--7) Smaž všechny instituce, které mají region 'CZ' a souèasnì nejsou veøejné
DELETE FROM z_institution_copy
WHERE region LIKE 'CZ' AND is_public = 1

--8) Vypiš poèet záznamù po mazání
select COUNT(*)
from z_institution_copy 
where name LIKE '%s.r.o.'

--9) Pøidej sloupec created_on DATE
--	s CHECK že datum musí být vìtší nebo rovno 2020-01-01
ALTER TABLE z_institution_copy
ADD created_on DATE
	CONSTRAINT created_on_ok check (created_on>='2020-01-01')

--10) Pokus se vložit:
--jeden záznam splòující check
--jeden porušující check
--Zapiš JAK se jmenovalo omezení.
insert into z_institution_copy (iid,name,created_on)
	values (5000,'neporusujici pravidlo','2020-01-01'),
			(5001,'porusujici check', '2019-12-30')

--11) Odstraò check

ALTER TABLE z_institution_copy
DROP CONSTRAINT created_on_ok

--zkus znovu vložit problémový øádek
insert into z_institution_copy (iid,name,created_on)
	values (5001,'porusujici check', '2019-12-30')

select * from z_institution_copy

--12) Smaž celou tabulku
DROP TABLE z_institution_copy
---- TEST 2 - SQL JDD ----
-- 1. Vytvořte tabulku s názvem z_autor_vsb se stejnými atributy a primárním klíčem jako 
-- tabulka z_author (atribut rid nebude označen jako identity) a dalším atributem 
-- faculty varchar(3), jehož hodnota může být null.
CREATE TABLE z_autor_vsb (
	zav_identity INT NOT NULL PRIMARY KEY,
	zav_name VARCHAR(200) NOT NULL,
	zav_vedidk INT ,
	zav_faculty VARCHAR(3)
);

select * from z_author
select * from z_autor_vsb

-- 2. Do tabulky z_autor_vsb vložte jedním příkazem insert - select všechny záznamy autorů, kteří
-- jsou autory článků, u kterých je uvedena instituce 
-- 'Vysoká škola báňská - Technická univerzita Ostrava'. 
-- Hodnotu atribut faculty nastavte explicitně na null.
INSERT INTO z_autor_vsb
SELECT DISTINCT aut.*, null
FROM z_author aut  JOIN z_article_author aaut on aut.rid=aaut.rid
	JOIN z_article ar ON ar.aid=aaut.aid
	JOIN z_article_institution ai on ai.aid=ar.aid
	JOIN z_institution i ON i.iid=ai.iid
WHERE i.name LIKE 'Vysoká škola báňská - Technická univerzita Ostrava'

-- Napište dotaz, který vrátí počet záznamů tabulky z_autor_vsb.
SELECT COUNT(*) AS pocetZaznamu
from z_autor_vsb

-- 3. Aktualizujte hodnotu atributu faculty tabulky z_author_vsb na hodnotu 'fei' u všech záznamů.
UPDATE z_autor_vsb 
SET zav_faculty='fei'

-- 4. Napište dotaz vracející počet autorů z tabulky z_author_vsb, kteří jsou z fakulty 'fei' 
-- a druhý dotaz pro počet autorů z fakulty 'fs'.

SELECT COUNT(*)
FROM z_autor_vsb
WHERE zav_faculty LIKE 'fei'

SELECT COUNT(*)
FROM z_autor_vsb
WHERE zav_faculty LIKE 'fs'

-- 5. Do tabulky z_author_vsb přidejte atribut department int jehož hodnota může být null.
ALTER TABLE z_autor_vsb
ADD department INT 

SELECT * FROM z_autor_vsb


-- 6. Aktualizujte hodnotu atributu department tabulky z_author_vsb na 460 pro autory se jmény
-- začínajícími na 'S'. Vypište počet autorů z katedry 460.
UPDATE z_autor_vsb
SET department = 460
WHERE zav_name LIKE 'S%'

SELECT COUNT(*)
FROM z_autor_vsb
WHERE department = 460

-- 7. Aktualizujte hodnotu atributu department tabulky z_author_vsb na 460 pro autory se jmény
-- začínajícími na 'S'. Pro všechny ostatní autory nastavte hodnotu department na 470. Řešte jedním 
-- příkazem update.
UPDATE z_autor_vsb
SET department = CASE 
				WHEN zav_name LIKE 'S%' THEN 460
				WHEN zav_name NOT LIKE 'S%' THEN 470
				END

-- 8. Vypište počet autorů z katedry 460 a druhým dotazem počet autorů z katedry 470.
SELECT COUNT(*) AS pocet_autoru_z_katedry_460
FROM z_autor_vsb
WHERE department = 460

SELECT COUNT(*) AS pocet_autoru_z_katedry_470
FROM z_autor_vsb
WHERE department = 470

-- 9. Z tabulky z_author_vsb smažte všechny záznamy s katedrou 470 a dalším dotazem zjistěte
-- aktuální počet záznamů v tabulce.
DELETE 
FROM z_autor_vsb 
WHERE department = 470

SELECT COUNT(*)
FROM z_autor_vsb

-- 10. Do tabulky z_author_vsb přidejte atribut last_update typu date s kontrolou hodnoty pomocí
-- check >= '2025-11-11'. 
-- A pokuste se přidat dva záznamy: jeden vyhovující podmínce a druhý
-- nevyhovující podmínce (a zapište se název integritního omezení pro check).

ALTER TABLE z_autor_vsb
ADD last_update date
	CONSTRAINT ok_last_upadet check (last_update>='2025-11-11')

INSERT INTO z_autor_vsb (zav_identity,zav_name,last_update)
	VALUES (100000,'vyhovujici podmince','2025-11-11'),
			(100001,'nevyhovujici podmince','2025-10-10')

-- 11. Zrušte integritní omezení check pro lastupdate (alter table ... drop constraint ...) a 
-- pokust se znovu  vložit neúspěšně vložený záznam.

ALTER TABLE z_autor_vsb
DROP CONSTRAINT ok_last_upadet

INSERT INTO z_autor_vsb (zav_identity,zav_name,last_update)
	VALUES (100001,'nevyhovujici podmince','2025-10-10')

-- 12. Zrušte tabulku z_author_vsb.
DROP TABLE z_autor_vsb


--DALSI!!!!!!
--Vytvoř tabulku z_institution_copy
--stejné atributy jako z_institution
--primární klíč jako v originálu
--navíc atribut region VARCHAR(50), který může být NULL
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

--Vlož do z_institution_copy všechny instituce z měst obsahující „Praha“
--jedním Insert–Select
--region nastav na 'CZ'
INSERT INTO z_institution_copy 
	SELECT *,'CZ'
	FROM z_institution
	WHERE town LIKE '%Praha%'

--3) Vypiš počet vložených institucí
SELECT COUNT(*)
FROM z_institution_copy

--4) Přidej do tabulky atribut is_public INT NOT NULL DEFAULT(1)
ALTER TABLE z_institution_copy 
ADD is_public INT NOT NULL DEFAULT(1)

--5) Aktualizuj:
--nastav is_public = 0 pro instituce, jejichž jméno obsahuje „s.r.o.“
--ostatním nech původní hodnotu
--(Jeden UPDATE.)
UPDATE  z_institution_copy 
SET is_public = 0 
WHERE name LIKE '%s.r.o.'

select*from z_institution_copy where name LIKE '%s.r.o.'

--6) Vypiš počet „soukromých“ (is_public=0)
select COUNT(*)
from z_institution_copy 
where name LIKE '%s.r.o.'

--7) Smaž všechny instituce, které mají region 'CZ' a současně nejsou veřejné
DELETE FROM z_institution_copy
WHERE region LIKE 'CZ' AND is_public = 1

--8) Vypiš počet záznamů po mazání
select COUNT(*)
from z_institution_copy 
where name LIKE '%s.r.o.'

--9) Přidej sloupec created_on DATE
--	s CHECK že datum musí být větší nebo rovno 2020-01-01
ALTER TABLE z_institution_copy
ADD created_on DATE
	CONSTRAINT created_on_ok check (created_on>='2020-01-01')

--10) Pokus se vložit:
--jeden záznam splňující check
--jeden porušující check
--Zapiš JAK se jmenovalo omezení.
insert into z_institution_copy (iid,name,created_on)
	values (5000,'neporusujici pravidlo','2020-01-01'),
			(5001,'porusujici check', '2019-12-30')

--11) Odstraň check

ALTER TABLE z_institution_copy
DROP CONSTRAINT created_on_ok

--zkus znovu vložit problémový řádek
insert into z_institution_copy (iid,name,created_on)
	values (5001,'porusujici check', '2019-12-30')

select * from z_institution_copy

--12) Smaž celou tabulku
DROP TABLE z_institution_copy





--Vytvoř tabulku z_article_log
--atributy:
--entry_id INT PRIMARY KEY
--aid INT NOT NULL
--log_date DATE NOT NULL
--note VARCHAR(200) NULL
--FK na z_article(aid)
CREATE TABLE z_article_log(
	entry_id INT PRIMARY KEY,
	aid INT NOT NULL FOREIGN KEY REFERENCES z_article(aid),
	log_date DATE NOT NULL,
	note VARCHAR(200) NULL,
)

--2) Vlož všechny články z roku 2020
--každý dostane log_date = '2025-01-01'
--note = 'imported'
INSERT INTO z_article_log (entry_id, aid, log_date, note)
SELECT 
    ROW_NUMBER() OVER (ORDER BY aid) AS entry_id,
    aid,
    '2025-01-01',
    'imported'
FROM z_article
WHERE year = 2020;

--3) Vypiš kolik jsi vložil záznamů
SELECT COUNT(*)
FROM z_article_log

--4) Přidej sloupec priority INT s DEFAULT 1
ALTER TABLE z_article_log
ADD priority INT DEFAULT 1

--Aktualizuj:
--priority = 5 pro články z časopisů ranking 'Q1'
--priority = 3 pro Q2
--priority = 1 pro ostatní
--(jeden UPDATE + CASE + join)
UPDATE al
SET al.priority = CASE
        WHEN yfj.ranking = 'Q1' THEN 5
        WHEN yfj.ranking = 'Q2' THEN 3
        ELSE 1
    END
FROM z_article_log al
JOIN z_article ar ON al.aid = ar.aid
JOIN z_journal jou ON ar.jid = jou.jid
JOIN z_year_field_journal yfj ON yfj.jid=jou.jid;

--6) Vypiš počet logů s priority 5
SELECT * 
FROM z_article_log
WHERE priority = 5

--Smaž všechny logy článků, které nepatří žádné instituci obsahující „University“
DELETE al
FROM z_article_log al
JOIN z_article ar ON al.aid = ar.aid
JOIN z_article_institution ai ON ai.aid=ar.aid
JOIN z_institution i ON ai.iid=i.iid
WHERE i.name LIKE '%University%'

--8) Vypiš nový počet záznamů
SELECT COUNT(*)
FROM z_article_log

--9) Přidej CHECK že log_date >= '2024-01-01'
ALTER TABLE z_article_log
ADD CONSTRAINT chk_logdate_ok
CHECK (log_date >= '2024-01-01');

--10) Zkus vložit nevalidní log_date → očekávaná chyba
INSERT INTO z_article_log (entry_id, aid, log_date, note)
VALUES (9999, 1, '2023-12-31', 'invalid test');


--11) Drop constraint → vlož znovu
ALTER TABLE z_article_log
DROP CONSTRAINT chk_logdate_ok;

--12) Drop tabulku
DROP TABLE z_article_log;


INSERT INTO actor(first_name,last_name)
VALUES ('Arnold','Schwarzenegger')

INSERT INTO film(title,description,language_id,length,release_year,rating,special_features)
VALUES('TERMINATOR',
       'Z roku 2029 je do Los Angeles roku 1984,',
       1,
       1984,
       187,
       'PG-13',
       'Trailers');

	   select * from film where title like 'TERMINATOR'

	   	   select * from actor where first_name like 'Arnold'


	   insert into film_actor(actor_id,film_id)
	   values(201,1001)

	   INSERT INTO film_category(category_id,film_id)
	   select category_id,1001
	   from category
	   where name IN ('Action','Sci-Fi')

update film
set rental_rate = 2.99,last_update= CURRENT_TIMESTAMP
where title like 'TERMINATOR'

select * from film

update film
set rental_rate = rental_rate * 1.1
where film_id in (select fa.film_id
					from film_actor fa join actor ac on ac.actor_id=fa.actor_id
					where ac.first_name like 'ZERO' AND ac.last_name like 'CAGE')

select * from language



--6
update film
set language_id = NULL 
where language_id =4

update film
set original_language_id = NULL 
where original_language_id =4

delete from language
where name like 'Mandarin'


--5 
insert into inventory(film_id,store_id)
select fa.film_id,2
					from film_actor fa join actor ac on ac.actor_id=fa.actor_id
					where ac.first_name like 'GROUCHO' AND ac.last_name like 'SINATRA'
--8
select * from customer

delete rental
where customer_id IN (select customer_id from customer
where active like '0')

delete payment
where customer_id IN (select customer_id from customer
where active like '0')

delete from customer
where active like '0'

--9
ALTER TABLE film
add inventory_count int 

select * from film
update film
set inventory_count = (select count(*) from inventory where film_id=film.film_id)


alter table category
alter column name varchar(50)

--11
select * from address
alter table customer 
ADD phone VARCHAR(20) not null default ' '


UPDATE customer 
SET customer.phone = (
    SELECT ad.phone
    FROM address ad
    WHERE ad.address_id = customer.address_id
);

--12
alter table rental
add create_date datetime not null 
	CONSTRAINT IO_default_timestamp_create_date default CURRENT_TIMESTAMP

alter table rental
drop constraint IO_default_timestamp_create_date

alter table rental
drop column create_date

--14
alter table film
add creator_staff_id tinyint 
	CONSTRAINT FK_TO_STAFF foreign key references staff(staff_id)

		alter table film 
	drop constraint FK_TO_STAFF

	alter table film 
	drop column creator_staff_id


--18
CREATE TABLE reservation (
	reservation_id int primary key identity,
	reservation_date date not null ,
	end_date date not null,
	custommer_id int references customer(customer_id),
	film_id int references film,
	staff_id tinyint references staff
)

--19
insert into reservation
 values ('2025-11-18','2025-11-19',1,1,1)
 insert into reservation
 values ('2025-11-18','2025-11-19',1,1,1)

 select * from reservation


--23
CREATE TABLE rating(
rating_id int identity primary key,
name varchar(10) not null,
description varchar
)

insert into rating (name)
select distinct rating
from film 

select * from rating

alter table film
add rating_id int default 1 not null references rating

update film
set film.rating_id = (select rating_id from rating where rating.name LIKE film.rating)

select * from film

--ZADANI:
--5 -----------------------------------------------
insert into inventory(film_id,store_id)
select fa.film_id,2
					from film_actor fa join actor ac on ac.actor_id=fa.actor_id
					where ac.first_name like 'GROUCHO' AND ac.last_name like 'SINATRA'
--8-----------------------------------------
select * from customer

delete rental
where customer_id IN (select customer_id from customer
where active like '0')

delete payment
where customer_id IN (select customer_id from customer
where active like '0')

delete from customer
where active like '0'

--11---------------------------------------------
select * from address
alter table customer 
ADD phone VARCHAR(20) not null default ' '


UPDATE customer 
SET customer.phone = (
    SELECT ad.phone
    FROM address ad
    WHERE ad.address_id = customer.address_id
);


--14------------------------------------------
alter table film
add creator_staff_id tinyint 
	CONSTRAINT fk film staff foreign key references staff(staff_id)

		alter table film 
	drop constraint fk film staff

	alter table film 
	drop column creator_staff_id

--19-------------------------------------
insert into reservation
 values ('2025-11-18','2025-11-19',1,1,1)
 insert into reservation
 values ('2025-11-18','2025-11-19',1,1,1)

 select * from reservation



 --23--------------------------------------
CREATE TABLE rating(
rating_id int identity primary key,
name varchar(10) not null,
description varchar
)

insert into rating (name)
select distinct rating
from film 

select * from rating

alter table film
add rating_id int default 1 references rating

update film
set film.rating_id = (select rating_id from rating where rating.name LIKE film.rating)

select * from film

alter table film 
drop constraint CHECK_special_rating

alter table film 
drop column rating

-- 5 bodu!!

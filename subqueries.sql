/* ============================================================
   1️  Autoři z článků, kde instituce sídlí v Ostravě
   ============================================================ */
SELECT DISTINCT aut.rid, aut.name
FROM z_article ar
    JOIN z_article_author aau ON aau.aid = ar.aid
    JOIN z_author aut ON aut.rid = aau.rid
    JOIN z_article_institution ai ON ai.aid = ar.aid
    JOIN z_institution i ON i.iid = ai.iid
WHERE i.town LIKE '%Ostrava%'
ORDER BY aut.rid;


/* ============================================================
   2️ Instituce, kde působí konkrétní autor (Pumera, Martin)
   ============================================================ */
SELECT DISTINCT ai.iid, aut.name
FROM z_article ar
    JOIN z_article_author aau ON aau.aid = ar.aid
    JOIN z_author aut ON aut.rid = aau.rid
    JOIN z_article_institution ai ON ai.aid = ar.aid
WHERE aut.name LIKE 'Pumera, Martin'
ORDER BY ai.iid;


/* ============================================================
   3️ Články publikované v časopisech s rankingem "Decil"
   ============================================================ */
SELECT DISTINCT ar.aid
FROM z_article ar
    JOIN z_journal ju ON ar.jid = ju.jid
    JOIN z_year_field_journal yfj ON yfj.jid = ju.jid
WHERE (ar.year = yfj.year)
  AND yfj.ranking LIKE 'Decil'
ORDER BY ar.aid;


/* ============================================================
   4️  Články v časopisech s rankingem "Decil" z VŠB
   ============================================================ */
SELECT DISTINCT ar.aid
FROM z_article ar
    JOIN z_journal ju ON ar.jid = ju.jid
    JOIN z_year_field_journal yfj ON yfj.jid = ju.jid
    JOIN z_article_institution ai ON ai.aid = ar.aid
    JOIN z_institution i ON i.iid = ai.iid
WHERE (ar.year = yfj.year)
  AND yfj.ranking LIKE 'Decil'
  AND i.name LIKE 'Vysoká%báňská%'
ORDER BY ar.aid;


/* ============================================================
   5️  Počet článků jednotlivých autorů z VŠB
        v oboru "Computer and Information Sciences"
        a rankingu "Decil" nebo "Q1"
   ============================================================ */
SELECT DISTINCT aut.rid, aut.name, COUNT(ar.aid) AS pocet
FROM z_article ar
    JOIN z_journal ju ON ar.jid = ju.jid
    JOIN z_year_field_journal yfj ON yfj.jid = ju.jid
    JOIN z_article_institution ai ON ai.aid = ar.aid
    JOIN z_institution i ON i.iid = ai.iid
    JOIN z_field_ford ff ON ff.fid = yfj.fid
    JOIN z_article_author aa ON aa.aid = ar.aid
    JOIN z_author aut ON aut.rid = aa.rid
WHERE (ar.year = yfj.year)
  AND ff.name LIKE '1.2 Computer and Information Sciences'
  AND yfj.ranking IN ('Decil', 'Q1')
  AND i.name LIKE 'Vysoká%báňská%'
GROUP BY aut.rid, aut.name;


/* ============================================================
   6️  Autor – počet článků v Decil a Q1 (pomocí poddotazů)
   ============================================================ */
SELECT DISTINCT
    aut.rid,
    aut.name,
    (
        SELECT COUNT(a2.aid)
        FROM z_article a2
            JOIN z_article_author aa2 ON aa2.aid = a2.aid
            JOIN z_author aut2 ON aut2.rid = aa2.rid
            JOIN z_article_institution ai2 ON ai2.aid = a2.aid
            JOIN z_institution i2 ON i2.iid = ai2.iid
            JOIN z_journal ju2 ON a2.jid = ju2.jid
            JOIN z_year_field_journal yfj2 ON ju2.jid = yfj2.jid
        WHERE yfj2.ranking LIKE 'Decil'
          AND i2.name LIKE 'Vysoká%báňská%'
          AND aut2.rid = aut.rid
    ) AS pocet_decil,
    (
        SELECT COUNT(a3.aid)
        FROM z_article a3
            JOIN z_article_author aa3 ON aa3.aid = a3.aid
            JOIN z_author aut3 ON aut3.rid = aa3.rid
            JOIN z_article_institution ai3 ON ai3.aid = a3.aid
            JOIN z_institution i3 ON i3.iid = ai3.iid
            JOIN z_journal ju3 ON a3.jid = ju3.jid
            JOIN z_year_field_journal yfj3 ON ju3.jid = ju3.jid
        WHERE yfj3.ranking LIKE 'Q1'
          AND i3.name LIKE 'Vysoká%báňská%'
          AND aut3.rid = aut.rid
    ) AS pocet_q1
FROM z_article ar
    JOIN z_journal ju ON ar.jid = ju.jid
    JOIN z_article_institution ai ON ai.aid = ar.aid
    JOIN z_institution i ON i.iid = ai.iid
    JOIN z_article_author aa ON aa.aid = ar.aid
    JOIN z_author aut ON aut.rid = aa.rid
WHERE i.name LIKE 'Vysoká%báňská%'
ORDER BY pocet_decil DESC, pocet_q1 DESC;


/* ============================================================
   7️  Efektivnější varianta pomocí CASE – počty Decil a Q1
   ============================================================ */
SELECT
    aut.rid,
    aut.name,
    SUM(CASE WHEN yfj.ranking LIKE 'Decil' THEN 1 ELSE 0 END) AS pocet_decil,
    SUM(CASE WHEN yfj.ranking LIKE 'Q1' THEN 1 ELSE 0 END) AS pocet_q1
FROM z_article ar
    JOIN z_journal ju ON ar.jid = ju.jid
    JOIN z_year_field_journal yfj ON ju.jid = yfj.jid
    JOIN z_article_author aa ON aa.aid = ar.aid
    JOIN z_author aut ON aut.rid = aa.rid
    JOIN z_article_institution ai ON ai.aid = ar.aid
    JOIN z_institution i ON i.iid = ai.iid
WHERE i.name LIKE 'Vysoká%báňská%'
GROUP BY aut.rid, aut.name
ORDER BY pocet_decil DESC, pocet_q1 DESC;


/* ============================================================
   8️  Nejproduktivnější časopisy podle oboru (Engineering)
        – pomocí poddotazu
   ============================================================ */
SELECT * 
FROM (
    SELECT ff.name AS field, jo.name, COUNT(ar.aid) AS pocet
    FROM z_field_ford ff
        JOIN z_field_of_science fos ON fos.sid = ff.sid
        JOIN z_year_field_journal yfj ON yfj.fid = ff.fid
        JOIN z_journal jo ON jo.jid = yfj.jid
        JOIN z_article ar ON ar.jid = jo.jid
    WHERE (ar.year = yfj.year)
      AND ar.year = 2020
      AND fos.name LIKE 'Engineering and Technology'
    GROUP BY ff.name, fos.name, jo.name
) AS counts
WHERE pocet = (
    SELECT MAX(C2.pocet2)
    FROM (
        SELECT ff.name AS field, jo.name, COUNT(ar.aid) AS pocet2
        FROM z_field_ford ff
            JOIN z_field_of_science fos ON fos.sid = ff.sid
            JOIN z_year_field_journal yfj ON yfj.fid = ff.fid
            JOIN z_journal jo ON jo.jid = yfj.jid
            JOIN z_article ar ON ar.jid = jo.jid
        WHERE (ar.year = yfj.year)
          AND ar.year = 2020
          AND fos.name LIKE 'Engineering and Technology'
        GROUP BY ff.name, fos.name, jo.name
    ) AS C2
    WHERE C2.field = counts.field
);


/* ============================================================
   9️  Totéž pomocí CTE (WITH)
   ============================================================ */
WITH counts_articles AS (
    SELECT ff.name AS field, jo.name, COUNT(ar.aid) AS pocet
    FROM z_field_ford ff
        JOIN z_field_of_science fos ON fos.sid = ff.sid
        JOIN z_year_field_journal yfj ON yfj.fid = ff.fid
        JOIN z_journal jo ON jo.jid = yfj.jid
        JOIN z_article ar ON ar.jid = jo.jid
    WHERE (ar.year = yfj.year)
      AND ar.year = 2020
      AND fos.name LIKE 'Engineering and Technology'
    GROUP BY ff.name, fos.name, jo.name
),
maxFields AS (
    SELECT field, MAX(pocet) AS maximum
    FROM counts_articles
    GROUP BY field
)
SELECT ca.*
FROM counts_articles ca
    JOIN maxFields ma ON ma.field = ca.field
WHERE ca.pocet = ma.maximum;


/* ============================================================
   🔟  Obory s časopisy bez článků (pocetClanku = 0)
   ============================================================ */
WITH counts_articles AS (
    SELECT ff.name AS field, jo.name AS jmenoCasopisu, COUNT(ar.aid) AS pocetClanku
    FROM z_field_ford ff
        JOIN z_field_of_science fos ON fos.sid = ff.sid
        JOIN z_year_field_journal yfj ON yfj.fid = ff.fid
        JOIN z_journal jo ON jo.jid = yfj.jid
        LEFT JOIN z_article ar ON ar.jid = jo.jid
    WHERE yfj.year = 2020
      AND fos.name LIKE 'Engineering and Technology'
    GROUP BY ff.name, jo.name
)
SELECT field AS obor, COUNT(jmenoCasopisu) AS pocetCasopisuBezClanku, pocetClanku
FROM counts_articles
WHERE pocetClanku = 0
GROUP BY field, pocetClanku;


/* ============================================================
   1️1  Časopisy, které byly v roce 2020 Q1 a v 2021 Q2
          v oboru 5.5 Law
   ============================================================ */
SELECT jo.* 
FROM z_journal jo
    JOIN z_year_field_journal yfj ON yfj.jid = jo.jid
    JOIN z_field_ford ff ON ff.fid = yfj.fid
    JOIN z_field_of_science fos ON fos.sid = ff.sid
WHERE (yfj.year = 2020 AND yfj.ranking LIKE 'Q1' AND ff.name LIKE '5.5 Law')
  AND jo.jid IN (
        SELECT jo.jid
        FROM z_journal jo
            JOIN z_year_field_journal yfj ON yfj.jid = jo.jid
            JOIN z_field_ford ff ON ff.fid = yfj.fid
            JOIN z_field_of_science fos ON fos.sid = ff.sid
        WHERE (yfj.year = 2021 AND yfj.ranking LIKE 'Q2' AND ff.name LIKE '5.5 Law')
  );

-- ============================================
-- 1️2 Autoři z Ostravy s více než (průměr + 15) články v Q1
-- ============================================

WITH autoriAPocty AS (
    -- Spočítáme, kolik Q1 článků má každý autor z Ostravy
    SELECT 
        aut.rid AS idAutora,
        aut.name AS jmenoAutora,
        COUNT(DISTINCT ar.aid) AS pocet
    FROM z_article ar 
        JOIN z_article_institution ari ON ari.aid = ar.aid
        JOIN z_institution i ON i.iid = ari.iid
        JOIN z_journal jo ON jo.jid = ar.jid
        JOIN z_year_field_journal yfj ON yfj.jid = jo.jid AND yfj.year = ar.year
        JOIN z_article_author aaut ON aaut.aid = ar.aid
        JOIN z_author aut ON aut.rid = aaut.rid
    WHERE 
        i.town LIKE '%Ostrava%'        -- pouze instituce obsahující "Ostrava"
        AND yfj.ranking LIKE 'Q1'      -- pouze časopisy hodnocené Q1
    GROUP BY aut.rid, aut.name
)
-- Vybereme jen ty autory, kteří mají o 15 článků více než průměr všech autorů
SELECT *
FROM autoriAPocty aap
WHERE aap.pocet - 15 >= (
    SELECT AVG(aap.pocet)
    FROM autoriAPocty aap
);


-- ============================================
-- 2️⃣ Instituce z Olomouce s podmínkami na FORD a počet článků
-- ============================================

WITH spravneInstituce AS (
    -- Najdeme instituce z Olomouce a články z daných let v oboru Medical and Health Sciences
    SELECT DISTINCT 
        i.iid AS idInstituce,
        ar.aid AS idClanku,
        COUNT(DISTINCT ar.aid) AS pocetClanku
    FROM z_article ar 
        JOIN z_article_institution ari ON ari.aid = ar.aid
        JOIN z_institution i ON i.iid = ari.iid
        JOIN z_journal jo ON jo.jid = ar.jid
        JOIN z_year_field_journal yfj ON yfj.jid = jo.jid AND yfj.year = ar.year
        JOIN z_field_ford ff ON ff.fid = yfj.fid
        JOIN z_field_of_science fos ON fos.sid = ff.sid
    WHERE 
        i.town LIKE 'Olomouc'
        AND fos.name LIKE 'Medical and Health Sciences'
        AND ar.year IN (2018,2019,2020,2021)
    GROUP BY i.iid, ar.aid
)
-- Vybereme instituce, které buď:
--  - mají články s 1–2 různými FORD poli
--  - nebo mají alespoň 5 článků celkem
SELECT DISTINCT idInstituce
FROM spravneInstituce 
WHERE idClanku IN (
    SELECT ar.aid
    FROM z_article ar 
        JOIN z_journal jo ON jo.jid = ar.jid
        JOIN z_year_field_journal yfj ON yfj.jid = jo.jid AND yfj.year = ar.year
        JOIN z_field_ford ff ON ff.fid = yfj.fid
        JOIN z_field_of_science fos ON fos.sid = ff.sid
    WHERE fos.name LIKE 'Medical and Health Sciences'
    GROUP BY ar.aid
    HAVING COUNT(ff.fid) IN (1,2)
)
OR idInstituce IN (
    SELECT i.iid
    FROM z_article ar 
        JOIN z_article_institution ari ON ari.aid = ar.aid
        JOIN z_institution i ON i.iid = ari.iid
    GROUP BY i.iid
    HAVING COUNT(ar.aid) = 5
);


-- ============================================
-- 3️⃣ Autoři z Plzně s nejvyšším počtem článků v časopisech typu "Decil"
-- ============================================

WITH SpravnniAutoriPoctyClanku AS (
    -- Spočítáme, kolik Decil článků má každý autor z Plzně
    SELECT 
        aut.rid AS id,
        aut.name AS jmeno,
        COUNT(DISTINCT ar.aid) AS pocet
    FROM z_article ar 
        JOIN z_article_institution ari ON ari.aid = ar.aid
        JOIN z_institution i ON i.iid = ari.iid
        JOIN z_journal jo ON jo.jid = ar.jid
        JOIN z_year_field_journal yfj ON yfj.jid = jo.jid AND yfj.year = ar.year
        JOIN z_article_author aaut ON aaut.aid = ar.aid
        JOIN z_author aut ON aut.rid = aaut.rid
    WHERE 
        yfj.ranking LIKE 'Decil'
        AND i.town LIKE '%Plzeň%'
    GROUP BY aut.rid, aut.name
)
-- Vybereme autora nebo autory s největším počtem Decil článků
SELECT *
FROM SpravnniAutoriPoctyClanku
WHERE pocet = (
    SELECT MAX(pocet)
    FROM SpravnniAutoriPoctyClanku
);

-- =====================================================================
-- Pro každý obor FORD z vědního oboru 'Engineering and Technology'
-- vypište jméno článku, publikovaném v daném oboru v Q1 časopisu
-- v letech 2018–2019 a který má nejvíce autorů.
-- Vypište jméno oboru, jméno článku a počet autorů.
-- Setřiďte podle názvu oboru a jména článku.
-- =====================================================================
WITH fordPocetAUtoru as
(
                        SELECT ff.name AS obor, ar.name AS clanek, COUNT(aaut.rid) as pocetAutoru --9856 radku
                        FROM z_article ar JOIN z_journal jou on ar.jid=jou.jid
                        JOIN z_year_field_journal yfj on yfj.jid=ar.jid AND yfj.year=ar.year
                        JOIN z_field_ford ff on ff.fid=yfj.fid
                        JOIN z_field_of_science fos on fos.sid=ff.sid
                        JOIN z_article_author aaut on aaut.aid=ar.aid
                            WHERE yfj.ranking LIKE 'Q1'
                            AND yfj.year IN (2018,2019)
                            AND fos.name LIKE 'Engineering and technology'
                            GROUP BY ff.name, ar.name
), maxPocetAutoru as 
(
                        SELECT  obor,MAX(pocetAutoru) AS maximalniPocetAutoru
                        FROM fordPocetAUtoru fpa
                        GROUP BY obor
)
SELECT distinct fpa.* 
FROM fordPocetAUtoru fpa JOIN maxPocetAutoru mpa ON mpa.maximalniPocetAutoru=fpa.pocetAutoru 
                                                    AND mpa.obor=fpa.obor

-- =====================================================================
-- Vypište, jaký byl rozdíl v počtu publikací v 'Decil' časopisech
-- mezi lety 2019 a 2020 v jednotlivých oborech FORD
-- z vědního oboru 'Engineering and Technology'.
-- Pro každý obor vypište FID, název oboru FORD,
-- počet publikací v roce 2019, počet publikací v roce 2020
-- a rozdíl mezi těmito dvěma hodnotami.
-- =====================================================================

WITH oboryPoctyClankuVLetech as 
(
                                SELECT ff.fid AS idOboru,ff.name AS obor,
                                SUM(CASE WHEN ar.year = 2019 THEN 1 ELSE 0 END) AS clanky_2019,
                                SUM(CASE WHEN ar.year = 2020 THEN 1 ELSE 0 END) AS clanky_2020
                                FROM z_article ar JOIN z_journal jou ON jou.jid=ar.jid
                                JOIN z_year_field_journal yfj ON yfj.jid=jou.jid AND ar.year=yfj.year
                                JOIN z_field_ford ff ON ff.fid=yfj.fid
                                JOIN z_field_of_science fos ON fos.sid=ff.sid
                                    WHERE ar.year in (2019,2020)
                                    AND yfj.ranking like 'Decil'
                                    AND fos.name like 'Engineering and Technology'
                                    GROUP BY ff.fid,ff.name 
)
SELECT *,clanky_2019-clanky_2020
FROM oboryPoctyClankuVLetech;


-- =====================================================================
-- Nalezněte obory FORD, kde v roce 2020 nikdy nebylo
-- na žádné publikaci více než 20 autorů.
-- =====================================================================
WITH oboryPocty AS (
    SELECT ff.name AS obor, ar.aid AS clanek, COUNT(DISTINCT aaut.rid) AS pocetAutoru
    FROM z_article ar
    JOIN z_journal jou ON jou.jid = ar.jid
    JOIN z_year_field_journal yfj ON yfj.jid = jou.jid AND yfj.year = ar.year
    JOIN z_field_ford ff ON ff.fid = yfj.fid
    JOIN z_article_author aaut ON aaut.aid = ar.aid
    WHERE ar.year = 2020
    GROUP BY ff.name, ar.aid
)
SELECT obor, MAX(pocetAutoru) AS maxAutoru
FROM oboryPocty
GROUP BY obor
    HAVING MAX(pocetAutoru) <= 20;


-- =====================================================================
-- Pro každý obor FORD z vědního oboru 'Social Sciences'
-- vypište jméno článku, publikovaném v daném oboru
-- v 'Decil' časopisu v letech 2019–2020 a který má nejvíce autorů.
-- Vypište jméno oboru, jméno článku a počet autorů.
-- Setřiďte podle názvu oboru a jména článku.
-- =====================================================================
WITH clankyPoctyAutoru AS
(
        SELECT ff.name AS obor,ar.name clanek, COUNT(aaut.rid) AS pocetAutoru
        FROM z_article ar JOIN z_journal jou ON jou.jid=ar.jid
        JOIN z_year_field_journal yfj ON yfj.jid=jou.jid AND yfj.year=ar.year
        JOIN z_field_ford ff ON ff.fid=yfj.fid
        JOIN z_field_of_science fos ON fos.sid=ff.sid
        JOIN z_article_author aaut ON aaut.aid=ar.aid
            WHERE fos.name like 'Social Sciences'
            AND ar.year in (2019,2020)
            AND yfj.ranking LIKE 'Decil'
            GROUP BY ff.name,ar.name
), maximalniPocetAutoru AS
(
        SELECT obor, MAX(pocetAutoru) AS maxAutoru
        FROM clankyPoctyAutoru
            GROUP BY obor
)
SELECT cpa.* 
FROM maximalniPocetAutoru mpa JOIN clankyPoctyAutoru cpa ON cpa.obor=mpa.obor 
                                                        AND  mpa.maxAutoru=cpa.pocetAutoru
    ORDER BY obor,cpa.clanek


-- =====================================================================
-- Vypište, jaký byl rozdíl v počtu publikací v 'Q1' časopisech
-- mezi lety 2019 a 2020 v jednotlivých oborech FORD
-- z vědního oboru 'Social Sciences'.
-- Pro každý obor vypište FID, název oboru FORD,
-- počet publikací v roce 2019, počet publikací v roce 2020
-- a rozdíl mezi těmito dvěma hodnotami.
-- =====================================================================
WITH obory2019 AS(
SELECT ff.name obor, COUNT(distinct ar.aid) AS clanky_2019
FROM z_article ar JOIN z_journal jou ON jou.jid=ar.jid
JOIN z_year_field_journal yfj ON yfj.jid=jou.jid AND ar.year=yfj.year
JOIN z_field_ford ff ON ff.fid=yfj.fid
JOIN z_field_of_science fos ON fos.sid=ff.sid
    WHERE yfj.ranking like 'Q1'
    AND ar.year = 2019
    AND fos.name LIKE 'Social Sciences'
    GROUP BY ff.name
),
obory2020 AS(
SELECT ff.name obor, COUNT(distinct ar.aid) AS clanky_2020
FROM z_article ar JOIN z_journal jou ON jou.jid=ar.jid
JOIN z_year_field_journal yfj ON yfj.jid=jou.jid AND ar.year=yfj.year
JOIN z_field_ford ff ON ff.fid=yfj.fid
JOIN z_field_of_science fos ON fos.sid=ff.sid
    WHERE yfj.ranking like 'Q1'
    AND ar.year = 2020
    AND fos.name LIKE 'Social Sciences'
    GROUP BY ff.name
)
SELECT o20.obor AS obor, COALESCE(o19.clanky_2019, 0) AS pocet2019, o20.clanky_2020 AS pocet20,
COALESCE(o19.clanky_2019, 0)-o20.clanky_2020 AS rozdil
FROM obory2019 o19 RIGHT JOIN obory2020 o20 ON o19.obor=o20.obor



-- =====================================================================
-- Nalezněte obory FORD, kde v roce 2019 nikdy nebylo
-- na žádné publikaci více než 10 autorů.
-- =====================================================================
WITH oboryClankyPoctyAutoru as
(
                SELECT ff.name obor,ar.name clanek,COUNT(aaut.rid) pocetAutoru
                FROM z_field_ford ff LEFT JOIN z_year_field_journal yfj ON yfj.fid=ff.fid
                LEFT JOIN z_journal jou ON jou.jid=yfj.jid AND yfj.year =2019
                LEFT JOIN z_article ar ON ar.jid=jou.jid AND ar.year=2019
                LEFT JOIN z_article_author aaut ON aaut.aid=ar.aid
                        GROUP BY  ff.name,ar.name
)SELECT obor
FROM oboryClankyPoctyAutoru
    GROUP BY obor
    HAVING MAX(pocetAutoru)<=10
-- =====================================================================
-- Pro každou instituci z Brna vypište články s největším počtem autorů
-- Seradit podle clanku
-- =====================================================================

with clankyInstituciZBrnaAPoctyAutoru as
(
                        SELECT i.name AS instituce,ar.name AS clanek, COUNT(DISTINCT aaut.rid) as pocetAutoru
                        FROM z_institution i join z_article_institution ai ON ai.iid=i.iid AND i.town like '%Brno%'
                        JOIN z_article ar on ar.aid=ai.aid 
                        JOIN z_article_author aaut on aaut.aid=ar.aid
                        GROUP BY i.name,ar.name      
), maximalniPocty as (
SELECT instituce, MAX(pocetAutoru) AS maxPocet
FROM clankyInstituciZBrnaAPoctyAutoru
GROUP BY instituce
)
SELECT cia.*
FROM maximalniPocty map join clankyInstituciZBrnaAPoctyAutoru cia ON map.maxPocet=cia.pocetAutoru 
                                                                AND map.instituce=cia.instituce
            ORDER BY cia.clanek


-- =====================================================================
-- Nalezněte časopisy ve ktrých v roce 2018 publikovala "Vysoká škola báňská - Technická univerzita Ostrava"
-- více než "Vysoké učení technické v Brně". setřidit podle časopisu
-- =====================================================================
WITH casopisyPoctyClankuBanska AS
(
                        SELECT jou.name AS casopis , COUNT(DISTINCT ar.aid) AS pocetClanku
                        FROM z_institution i join z_article_institution ai ON ai.iid=i.iid 
                        JOIN z_article ar on ar.aid=ai.aid 
                        JOIN z_journal jou ON jou.jid=ar.jid
                        WHERE i.name like 'Vysoká škola báňská - Technická univerzita Ostrava'
                            GROUP BY jou.name          
) ,casopisyPoctyClankuBrno AS
(
                        SELECT jou.name AS casopis , COUNT(DISTINCT ar.aid) AS pocetClanku
                        FROM z_institution i join z_article_institution ai ON ai.iid=i.iid 
                        JOIN z_article ar on ar.aid=ai.aid 
                        JOIN z_journal jou ON jou.jid=ar.jid
                        WHERE i.name like 'Vysoké učení technické v Brně'
                            GROUP BY jou.name          
)
SELECT banska.casopis,banska.pocetClanku,COALESCE(brno.pocetClanku,0)
FROM casopisyPoctyClankuBanska banska LEFT JOIN casopisyPoctyClankuBrno brno ON banska.casopis=brno.casopis
    WHERE banska.pocetClanku>COALESCE(brno.pocetClanku,0)
    ORDER BY banska.casopis

-- =====================================================================
-- Vypište autory začínající na "falt", kteří v roce 2018 nikdy nepublikovali na článku s méně než sto
-- autory. Vynechejte autory, kteří v roce 2018 nepublikovali vůbec. setřiďte podle jmena autora
-- =====================================================================
WITH pocty AS (
  SELECT ar.aid, COUNT(DISTINCT aaut.rid) AS pocet_autoru
  FROM z_article ar
  JOIN z_article_author aaut ON aaut.aid = ar.aid
  WHERE ar.year = 2018
  GROUP BY ar.aid
),
falt AS (
  SELECT aut.name AS autor, ar.aid
  FROM z_author aut
  JOIN z_article_author aaut ON aut.rid = aaut.rid
  JOIN z_article ar ON ar.aid = aaut.aid
  WHERE aut.name LIKE 'falt%' AND ar.year = 2018
)
SELECT f.autor,MIN(p.pocet_autoru)
FROM falt f
JOIN pocty p ON f.aid = p.aid
GROUP BY f.autor
HAVING MIN(p.pocet_autoru) >= 100
ORDER BY f.autor;

-- =====================================================================
-- Pro každý obor FORD z vědního oboru "Engigeering and technology" vypište jméno článku, publikovaném v daném
-- oboru v Q1 časopisu v letech 2018-2019 a který má nejvíce autorů. vypište jméno oboru, jméno článku a počet
-- autorů. Setřiďte podle názvu oboru a jménu článku
-- =====================================================================
with oboryClankyPoctyAutoru as 
(
    SELECT DISTINCT ff.name AS obor, ff.fid oborID,ar.name clanek, COUNT(DISTINCT aaut.rid) pocetAutoru
    FROM z_field_ford ff join z_field_of_science fos ON fos.sid=ff.sid
    JOIN z_year_field_journal yfj on yfj.fid=ff.fid
    JOIN z_journal jou ON jou.jid=yfj.jid
    JOIN z_article ar on ar.jid=yfj.jid AND yfj.year =ar.year
    JOIN z_article_author aaut on aaut.aid=ar.aid
        WHERE fos.name like 'Engineering and Technology' 
        AND yfj.year in (2019,2018)
        AND yfj.ranking like 'Q1'
            GROUP BY ff.name, ff.fid,ar.name
), maximalni as(
SELECT obor,MAX(pocetAutoru) maxpoc
FROM oboryClankyPoctyAutoru tab 
GROUP BY obor
)
SELECT ocpa.*
FROM oboryClankyPoctyAutoru ocpa join maximalni ma on ma.obor=ocpa.obor AND ma.maxpoc=ocpa.pocetAutoru


-- =====================================================================
-- Vypište jaký byl rozdíl v počtu publikací v Decil časopisech mezi lety 2019 a 2020 v jednotlivych oborech
-- FORD z vědního oboru 'Engineering and Technology'. Pro každý obor vypište FID, název oboru FORD, počet
-- publikací v roce 2019, počet publikací v roce 2020 a rozdíl mezi těmito dvěma hodnotami
-- =====================================================================
WITH tabulkaLetSUM AS 
(
                SELECT ff.name,ff.fid,
                SUM(CASE WHEN ar.year = 2019 THEN 1 ELSE 0 END) v2019,
                SUM(CASE WHEN ar.year = 2020 THEN 1 ELSE 0 END) v2020
                FROM z_field_ford ff join z_field_of_science fos ON fos.sid=ff.sid
                JOIN z_year_field_journal yfj on yfj.fid=ff.fid
                JOIN z_journal jou ON jou.jid=yfj.jid
                JOIN z_article ar on ar.jid=yfj.jid AND yfj.year =ar.year
                    WHERE yfj.year in (2020,2019)
                    AND yfj.ranking LIKE 'Decil'
                    AND fos.name like 'Engineering and Technology' 
                        GROUP BY  ff.name,ff.fid
)SELECT *, v2019-v2020
 FROM tabulkaLetSUM;

 WITH tabulkaLetCOUNT AS 
(
                SELECT ff.name,ff.fid,
COUNT(DISTINCT CASE WHEN ar.year = 2019 THEN ar.aid END) AS v2019,
COUNT(DISTINCT CASE WHEN ar.year = 2020 THEN ar.aid END) AS v2020
                FROM z_field_ford ff join z_field_of_science fos ON fos.sid=ff.sid
                JOIN z_year_field_journal yfj on yfj.fid=ff.fid
                JOIN z_journal jou ON jou.jid=yfj.jid
                JOIN z_article ar on ar.jid=yfj.jid AND yfj.year =ar.year
                    WHERE yfj.year in (2020,2019)
                    AND yfj.ranking LIKE 'Decil'
                    AND fos.name like 'Engineering and Technology' 
                        GROUP BY  ff.name,ff.fid
)SELECT *, v2019-v2020
 FROM tabulkaLetCOUNT;


-- =====================================================================
-- Naleznete obory FORD na kterych v roce 2020 nikdy nebylo vice nez 20 autoru
-- =====================================================================

WITH OboryPoctyAutoru AS
(
            SELECT ff.name AS obor,ar.name as clanek, COUNT(DISTINCT aaut.rid) pocetAutoru
            FROM z_field_ford ff LEFT JOIN z_year_field_journal yfj ON yfj.fid=ff.fid AND yfj.year =2020
            LEFT JOIN z_journal jou ON jou.jid=yfj.jid
            LEFT JOIN z_article ar on ar.jid=jou.jid AND ar.year=2020
            LEFT JOIN z_article_author aaut on aaut.aid=ar.aid
                GROUP BY ff.name,ar.name
)SELECT tab.obor,COALESCE(MAX(pocetAutoru), 0) AS maxAutoru
from OboryPoctyAutoru tab 
    GROUP BY  obor
    HAVING COALESCE(MAX(pocetAutoru), 0)<=20


 -- =====================================================================
-- Vypište průměrný počet autorů na články v oborech FORD z oblasti 'Natural sciences',
-- publikovaných v Q1 časopisech a spojených s institucí 'Nemocnice Na Homolce'.
-- Pro každý obor zobrazte název oboru a průměrný počet autorů na článek.
-- =====================================================================

WITH oboryClankyPoctyAutoru AS 
(
    SELECT ff.name AS obor, ff.fid oborID,ar.name clanek, COUNT(DISTINCT aaut.rid) pocetAutoru
    FROM z_field_ford ff join z_field_of_science fos ON fos.sid=ff.sid
    JOIN z_year_field_journal yfj on yfj.fid=ff.fid
    JOIN z_journal jou ON jou.jid=yfj.jid
    JOIN z_article ar on ar.jid=yfj.jid AND yfj.year =ar.year
    JOIN z_article_author aaut on aaut.aid=ar.aid
    JOIN z_article_institution ai ON ai.aid=ar.aid
    JOIN z_institution i ON i.iid=ai.iid
        WHERE fos.name like 'Natural sciences' 
        AND yfj.ranking like 'Q1'
        AND i.name like 'Nemocnice Na Homolce'
            GROUP BY ff.name, ff.fid,ar.name
)
SELECT obor, AVG(pocetAutoru)
FROM oboryClankyPoctyAutoru
    GROUP BY obor;

-- =====================================================================
--Naleznete instituce z ostravy nebo Olomouce, ktere maji alespoň jeden članek ohodnoceny jako Decil
-- ve všech letech:2018,2019,2020
-- =====================================================================
WITH instituceOstravaOlomou2018 AS
(
            SELECT i.name AS instituce
            FROM z_institution i join z_article_institution ai ON ai.iid=i.iid
            JOIN z_article ar ON ar.aid=ai.aid
            JOIN z_journal jou ON jou.jid=ar.jid
            JOIN z_year_field_journal yfj ON yfj.jid=jou.jid AND ar.year=yfj.year
                WHERE 
                (i.town LIKE '%Ostrava%' OR i.town LIKE '%Olomouc%')
                AND yfj.ranking like 'Decil'
                AND ar.year = 2018

), instituceOstravaOlomou2019 AS
(
            SELECT i.name AS instituce
            FROM z_institution i join z_article_institution ai ON ai.iid=i.iid
            JOIN z_article ar ON ar.aid=ai.aid
            JOIN z_journal jou ON jou.jid=ar.jid
            JOIN z_year_field_journal yfj ON yfj.jid=jou.jid AND ar.year=yfj.year
                WHERE 
                (i.town LIKE '%Ostrava%' OR i.town LIKE '%Olomouc%')
                AND yfj.ranking like 'Decil'
                AND ar.year = 2019

), instituceOstravaOlomou2020 AS
(
            SELECT i.name AS instituce
            FROM z_institution i join z_article_institution ai ON ai.iid=i.iid
            JOIN z_article ar ON ar.aid=ai.aid
            JOIN z_journal jou ON jou.jid=ar.jid
            JOIN z_year_field_journal yfj ON yfj.jid=jou.jid AND ar.year=yfj.year
                WHERE 
                (i.town LIKE '%Ostrava%' OR i.town LIKE '%Olomouc%')
                AND yfj.ranking like 'Decil'
                AND ar.year =2020
)
SELECT DISTINCT i20.instituce
FROM instituceOstravaOlomou2018 i18 JOIN instituceOstravaOlomou2019 i19 ON i18.instituce=i19.instituce
JOIN instituceOstravaOlomou2020 i20 ON i20.instituce=i18.instituce


--Stejne
SELECT i.name AS instituce
FROM z_institution i
JOIN z_article_institution ai ON ai.iid = i.iid
JOIN z_article ar ON ar.aid = ai.aid
JOIN z_journal jou ON jou.jid = ar.jid
JOIN z_year_field_journal yfj ON yfj.jid = jou.jid AND ar.year = yfj.year
WHERE (i.town LIKE '%Ostrava%' OR i.town LIKE '%Olomouc%')
  AND yfj.ranking LIKE 'Decil'
  AND ar.year IN (2018, 2019, 2020)
GROUP BY i.name
HAVING COUNT(DISTINCT ar.year) = 3;

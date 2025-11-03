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
    SELECT ff.name AS field, jo.name AS jmenoClanku, COUNT(ar.aid) AS pocetClanku
    FROM z_field_ford ff
        JOIN z_field_of_science fos ON fos.sid = ff.sid
        JOIN z_year_field_journal yfj ON yfj.fid = ff.fid
        JOIN z_journal jo ON jo.jid = yfj.jid
        LEFT JOIN z_article ar ON ar.jid = jo.jid
    WHERE yfj.year = 2020
      AND fos.name LIKE 'Engineering and Technology'
    GROUP BY ff.name, jo.name
)
SELECT field AS ford, COUNT(jmenoClanku) AS pocet2, pocetClanku
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
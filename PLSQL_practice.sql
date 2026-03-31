-- ==============================================================================
-- 1. BEZPEČNÉ SMAZÁNÍ INSTITUCE A VAZEB (Transakce a Výjimky)
-- ==============================================================================
-- Popis: Smaže instituci podle jména. Nejprve smaže vazby, pak instituci.
-- Chyták: SELECT INTO vyhodí NO_DATA_FOUND, pokud nic nenajde. SQL%ROWCOUNT vrací počet ovlivněných řádků předchozím DML.

CREATE TABLE work_z_institution AS SELECT * FROM z_institution;
CREATE TABLE work_z_article_institution AS SELECT * FROM z_article_institution;

CREATE OR REPLACE PROCEDURE P_DeleteInstitutionByName (p_inst_name VARCHAR2)
AS
    p_iid int := NULL;
    v_Deleted INT;
BEGIN
    IF p_inst_name IS NULL THEN
        dbms_output.put_line('NULL PARAM');
        RETURN; 
    END IF;

    SELECT iid INTO p_iid FROM work_z_institution WHERE name = p_inst_name;
    
    DELETE FROM work_z_article_institution WHERE iid = p_iid;
    v_deleted := SQL%ROWCOUNT; -- Počet smazaných vazeb
    
    DELETE FROM work_z_institution WHERE iid = p_iid;
    
    dbms_output.put_line('Instituce '||p_inst_name||' byla uspesne smazana.');
    dbms_output.put_line('Odstraneno zaznamu z vazebni tabulky: '||v_Deleted||'.');
    COMMIT; 

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('Instituce '||p_inst_name||' neexistuje.');
        ROLLBACK;
    WHEN OTHERS THEN
        dbms_output.put_line('Chyba pri mazani');
        ROLLBACK;
END P_DeleteInstitutionByName;
/

-- Spuštění:
BEGIN 
    P_DeleteInstitutionByName('METCENAS o.p.s.');
END;
/


-- ==============================================================================
-- 2. AUDITOVÁNÍ ZMĚN JMEN (AFTER UPDATE Trigger)
-- ==============================================================================
-- Popis: Loguje změny jména autora do samostatné tabulky, pokud má autor > 5 článků.
-- Chyták: FOR EACH ROW je nutné pro přístup k :OLD a :NEW. U triggeru se nevyplácí dělat ruční ROLLBACK, chyba se vyhazuje přes raise_application_error.

CREATE TABLE work_z_author AS SELECT * FROM z_author;
CREATE TABLE work_z_author_name_changes(
    rid int NOT NULL,
    old_name VARCHAR2(255) NOT NULL,
    new_name VARCHAR2(255) NOT NULL,
    change_time TIMESTAMP NOT NULL
);

CREATE OR REPLACE TRIGGER TR_AuthorNameAudit
AFTER UPDATE OF name ON work_z_author
FOR EACH ROW 
DECLARE 
    v_article_count int;
BEGIN
    SELECT COUNT(aid) INTO v_article_count 
    FROM z_article_author 
    WHERE rid = :OLD.rid;

    IF v_article_count > 5 THEN
        INSERT INTO work_z_author_name_changes VALUES (
            :OLD.rid, :OLD.name, :NEW.name, SYSTIMESTAMP
        );
    END IF;
EXCEPTION 
    WHEN OTHERS THEN
        raise_application_error(-20000, 'Chyba pri auditovani jmena');
END TR_AuthorNameAudit;
/

-- Spuštění:
UPDATE work_z_author SET name = 'Sharma, A. TEST' WHERE rid = 3604;
COMMIT;
SELECT * FROM work_z_author_name_changes;


-- ==============================================================================
-- 3. AUDIT SMAZANÝCH ČLÁNKŮ (AFTER DELETE Trigger)
-- ==============================================================================
-- Popis: Ukládá smazané články do logu, ale POUZE ty, které měly 3 a méně autorů.
-- Chyták: CTAS přes WHERE 1 = 0 vytvoří prázdnou tabulku se stejnou strukturou.

CREATE TABLE work_z_article AS SELECT * FROM z_article;
CREATE TABLE work_z_article_deleted AS SELECT * FROM work_z_article WHERE 1 = 0;

CREATE OR REPLACE TRIGGER TR_DeleteAudit
AFTER DELETE ON work_z_article
FOR EACH ROW
DECLARE
    v_authors_count INT;
BEGIN 
    SELECT COUNT(rid) INTO v_authors_count 
    FROM z_article_author -- čteme z originální vazební tabulky
    WHERE aid = :OLD.aid;
    
    -- Brzký konec, pokud má více než 3 autory
    IF v_authors_count > 3 THEN
        RETURN; 
    END IF;
    
    INSERT INTO work_z_article_deleted VALUES (
        :OLD.aid, :OLD.jid, :OLD.ut_wos, :OLD.type, :OLD.name, :OLD.year, :OLD.author_count
    );
EXCEPTION 
    WHEN OTHERS THEN
        raise_application_error(-20001,'CHYBA PRI AUDITOVANI MAZANYCH CLANKU');
END TR_DeleteAudit;
/

-- Spuštění:
DELETE FROM work_z_article WHERE aid = 2;


-- ==============================================================================
-- 4. DYNAMICKÁ TVORBA TABULKY DLE ROKU (Funkce a DDL)
-- ==============================================================================
-- Popis: Vytvoří tabulku článků pro konkrétní rok, přidá datum updatu, PK a FK. Vrací počet záznamů.
-- Chyták: V DDL (CREATE, ALTER) nefungují vázané proměnné (USING). Hodnoty se musí lepit přes ||.

CREATE OR REPLACE FUNCTION CreateArticleYear(p_year int) RETURN INT
AS
    v_sql VARCHAR(2000);
    v_ret int :=0;
BEGIN
    v_sql := 'CREATE TABLE z_article_year AS 
              SELECT a.*, SYSDATE AS last_update FROM z_article a WHERE YEAR = ' || p_year;
    EXECUTE IMMEDIATE v_sql;
    
    EXECUTE IMMEDIATE 'ALTER TABLE z_article_year ADD CONSTRAINT z_pk_aid PRIMARY KEY(aid)';
    EXECUTE IMMEDIATE 'ALTER TABLE z_article_year ADD CONSTRAINT fk_to_z_journal FOREIGN KEY(jid) REFERENCES z_journal(jid)';
    
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM z_article_year' INTO v_ret;
    
    EXECUTE IMMEDIATE 'DROP TABLE z_article_year';
    RETURN v_ret;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Chyba: ' || SQLERRM);
        RETURN -1;
END CreateArticleYear;
/

-- Spuštění:
BEGIN
    dbms_output.put_line('Clanku v roce 2021: '||CreateArticleYear(2021));
END;
/


-- ==============================================================================
-- 5. AGREGACE MĚST S LOGIKOU CREATE/REPLACE (Procedura)
-- ==============================================================================
-- Popis: Vytvoří/přepíše tabulku s agregovanými počty institucí dle měst.
-- Chyták: Systémové tabulky (USER_TABLES) mají data zásadně VELKÝMI PÍSMENY.

CREATE OR REPLACE PROCEDURE p_buildTownInstitutionStats(p_mode VARCHAR2)
AS
    v_table_exists int := 0;
    v_sql VARCHAR(2000);
    c_table CONSTANT VARCHAR2(50) := 'TOWN_INSTITUTION_STATS';
    ex_table_already_exists EXCEPTION;
BEGIN
    IF p_mode IS NULL OR p_mode NOT IN ('CREATE','REPLACE') THEN
        raise_application_error(-20000, 'Spatna hodnota parametru');
    END IF;

    -- Kontrola existence (DML dovoluje vázané proměnné)
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM user_tables WHERE table_name = :t_name' 
        INTO v_table_exists USING c_table;
    
    IF p_mode = 'CREATE' THEN
        IF v_table_exists > 0 THEN RAISE ex_table_already_exists; END IF;
    ELSIF p_mode = 'REPLACE' THEN
        IF v_table_exists > 0 THEN
            EXECUTE IMMEDIATE 'DROP TABLE ' || c_table;
        END IF;
    END IF;

    -- Tvorba tabulky
    v_sql := 'CREATE TABLE town_institution_stats AS 
                SELECT town, COUNT(*) AS institution_count 
                FROM z_INSTITUTION WHERE town IS NOT NULL GROUP BY town';
    EXECUTE IMMEDIATE v_sql;
    
EXCEPTION
    WHEN ex_table_already_exists THEN
        dbms_output.put_line('Chyba: tabulka jiz existuje a parametr = CREATE');
    WHEN OTHERS THEN 
        dbms_output.put_line('Neznama chyba: ' || SQLERRM); 
END p_buildTownInstitutionStats;
/

-- Spuštění:
BEGIN
    p_buildTownInstitutionStats('REPLACE');
END;
/


-- ==============================================================================
-- 6. DYNAMICKÝ COUNT(DISTINCT) PRO VŠECHNY SLOUPCE (Kurzor smyčka)
-- ==============================================================================
-- Popis: Projde všechny sloupce zadné tabulky (přes USER_TAB_COLUMNS) a zjistí počet unikátních hodnot.
-- Chyták: Názvy sloupců/tabulek nelze předat jako vázané proměnné (USING). Musí se řetězit (||).

CREATE OR REPLACE FUNCTION F_CountDistinctPerColumn(p_table_name VARCHAR2) RETURN VARCHAR2
IS
    v_ret VARCHAR2(2000) := '';
    v_table_exist INT := 0;
    v_sql VARCHAR2(2000);
    distinct_count INT := 0;
    v_upper_parameter VARCHAR2(100) := UPPER(p_table_name);
    
    CURSOR c_columns_names IS 
        SELECT column_name FROM user_tab_columns WHERE table_name = v_upper_parameter;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME = :p_t_name' 
        INTO v_table_exist USING v_upper_parameter;
        
    IF v_table_exist = 0 THEN
        dbms_output.put_line('TABULKA ' || p_table_name || ' NEEXISTUJE!'); 
        RETURN NULL;
    END IF;
    
    FOR one_col IN c_columns_names LOOP
        v_sql := 'SELECT COUNT(DISTINCT '|| one_col.column_name || ') FROM ' || v_upper_parameter;
        EXECUTE IMMEDIATE v_sql INTO distinct_count;
        v_ret := v_ret || one_col.column_name || '(' || distinct_count || '), ';
    END LOOP;

    RETURN RTRIM(v_ret, ', '); -- Odstranění poslední čárky a mezery
END F_CountDistinctPerColumn;
/
      
-- Spuštění:
BEGIN
    dbms_output.put_line(F_CountDistinctPerColumn('Z_INSTITUTION'));
END;
/


-- ==============================================================================
-- 7. PŘIDÁNÍ / ODEBRÁNÍ AUTORA ČLÁNKU (Funkce)
-- ==============================================================================
-- Popis: Mění vazbu článku a autora. Vrací 'I' (Přidáno), 'D' (Odebráno), 'N' (Žádná akce).

CREATE OR REPLACE FUNCTION F_SetArticleAuthors(p_aid INT, p_rid INT, p_set BOOLEAN) RETURN CHAR
IS
    v_author_asigned_to_article INT := 0;
BEGIN
    SELECT COUNT(*) INTO v_author_asigned_to_article 
    FROM z_article_author WHERE AID = p_aid AND RID = p_rid;
    
    IF (p_set = TRUE AND v_author_asigned_to_article !=0) OR (p_set = FALSE AND v_author_asigned_to_article =0) THEN 
        RETURN 'N';
    ELSIF p_set = TRUE THEN
        INSERT INTO z_article_author VALUES (p_aid,p_rid);
        UPDATE z_article SET author_count = author_count + 1 WHERE aid = p_aid;
        RETURN 'I';
    ELSIF p_set = FALSE THEN
        DELETE FROM z_article_author WHERE AID = p_aid AND RID = p_rid;
        UPDATE z_article SET author_count = author_count - 1 WHERE aid = p_aid;
        RETURN 'D';
    END IF;
    RETURN 'N';
EXCEPTION 
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line('CHYBA: ' || SQLERRM);
        RETURN 'E';
END F_SetArticleAuthors;
/

-- Spuštění:
BEGIN
    dbms_output.put_line('Vysledek: ' || F_SetArticleAuthors(119,588,FALSE));
END;
/


-- ==============================================================================
-- 8. POMOCNÁ PROCEDURA NA MAZÁNÍ TABULEK DLE NÁZVU (Kurzor s LIKE)
-- ==============================================================================
CREATE OR REPLACE PROCEDURE p_DropTablesLikeName(p_name VARCHAR2)
IS
    v_sql VARCHAR2(2000);
BEGIN
    FOR t_name IN (SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME LIKE UPPER(p_name)) LOOP
        dbms_output.put_line(t_name.TABLE_NAME||' SMAZANO');
        v_sql := 'DROP TABLE '|| t_name.TABLE_NAME;
        EXECUTE IMMEDIATE v_sql;
    END LOOP;                                   
END p_DropTablesLikeName;
/

-- Spuštění: (Smaže všechny tabulky začínající na REPORT)
BEGIN
    p_DropTablesLikeName('REPORT%');
END;
/


-- ==============================================================================
-- 9. GENEROVÁNÍ ROČNÍCH REPORTŮ PRO INSTITUCI (CTAS v cyklu)
-- ==============================================================================
-- Popis: Pro zadané ID instituce vygeneruje separátní tabulky pro každý rok, kdy byla aktivní.
-- Chyták: Neagregované sloupce musí být explicitně uvedeny v GROUP BY.

CREATE OR REPLACE PROCEDURE InstitutionReport(p_iid int) IS
    v_sql VARCHAR2(2000);
    v_tableCount int := 0;
BEGIN
    -- Kurzor zajistí, že nevzniknou tabulky pro roky bez aktivity
    FOR institutionYear IN (
        SELECT DISTINCT a.year
        FROM z_Article_institution ai JOIN z_Article a ON(a.aid = ai.aid)
        WHERE ai.iid = p_iid ORDER BY a.year
    ) LOOP
        SELECT COUNT(*) INTO v_tableCount FROM USER_TABLES 
        WHERE TABLE_NAME = UPPER('REPORT'||institutionYear.year);
        
        IF v_tableCount != 0 THEN
            EXECUTE IMMEDIATE 'DROP TABLE REPORT'|| institutionYear.year;
        END IF;
        
        -- DDL Create Table As Select (CTAS)
        v_sql := 'CREATE TABLE REPORT'|| institutionYear.year||' AS 
                    SELECT  ar.year AS rok,
                            aa.rid AS idAutora,
                            au.name AS jmenoAutora,
                            COUNT(DISTINCT ar.aid) AS pocetClanku,
                            COUNT(DISTINCT ar.jid) AS pocetCasopisu
                    FROM Z_AUTHOR au 
                    JOIN z_ARTICLE_AUTHOR aa ON (au.rid = aa.rid)
                    JOIN z_ARTICLE ar ON(ar.aid = aa.aid) AND ar.year = '||institutionYear.year||'
                    JOIN z_article_institution ai ON (ai.aid = ar.aid) AND ai.iid = '||p_iid||'
                    GROUP BY ar.year, aa.rid, au.name';
                    
        EXECUTE IMMEDIATE v_sql;
        dbms_output.put_line('REPORT'||institutionYear.year || ' Vytvoren.');
    END LOOP;
END InstitutionReport;
/
     
-- Spuštění:
BEGIN
    InstitutionReport(75);
END;
/


-- ==============================================================================
-- 10. OCHRANA TABULKY POMOCÍ BEFORE TRIGGERU (A past u LEFT JOIN)
-- ==============================================================================
-- Popis: Trigger zastaví ruční vkládání dat, pokud si uživatel vymýšlí a instituce ve skutečnosti nemá žádný článek.
-- Chyták LEFT JOIN: Podmínka WHERE ničí LEFT JOIN. Musí být součástí ON klauzule (jou.czech_or_slovak = 'NE').
-- Chyták CTAS: Každý počítaný sloupec MUSÍ mít AS název, jinak nelze vytvořit tabulku.

CREATE TABLE INSTITUTION_COUNT AS (     
    SELECT i.iid, 
           COUNT(jou.jid) AS article_count, 
           SYSTIMESTAMP AS sptamp 
    FROM Z_INSTITUTION i 
    LEFT JOIN Z_ARTICLE_INSTITUTION ai ON(i.iid = ai.iid)
    LEFT JOIN Z_ARTICLE ar ON (ar.aid = ai.aid)
    LEFT JOIN z_JOURNAL jou ON (jou.jid = ar.jid AND jou.czech_or_slovak = 'NE')
    GROUP BY i.iid
);
            
CREATE OR REPLACE TRIGGER t_institution_count
BEFORE INSERT OR UPDATE ON INSTITUTION_COUNT
FOR EACH ROW
DECLARE
    v_count INT := 0;
BEGIN
    SELECT COUNT(jou.jid) INTO v_count
    FROM Z_INSTITUTION i 
    LEFT JOIN Z_ARTICLE_INSTITUTION ai ON(i.iid = ai.iid)
    LEFT JOIN Z_ARTICLE ar ON (ar.aid = ai.aid)
    LEFT JOIN z_JOURNAL jou ON (jou.jid = ar.jid AND jou.czech_or_slovak = 'NE')
    WHERE i.iid = :NEW.iid; 
            
    IF v_count = 0 THEN 
        -- Záchranná brzda, shodí dotaz a provede automatický ROLLBACK.
        raise_application_error(-20001,'No article for institution');
    ELSE 
        -- Úprava hodnot "za letu" (Funguje pouze v BEFORE triggeru)
        :NEW.article_count := v_count;
        :NEW.sptamp := SYSTIMESTAMP;
    END IF;
END t_institution_count;
/

-- Test triggeru (Mělo by havarovat, pokud iid 1 nemá články):
INSERT INTO INSTITUTION_COUNT VALUES (1, 1000, SYSTIMESTAMP);



CREATE OR REPLACE TRIGGER T_CheckJournalConsistency
BEFORE INSERT OR DELETE OR UPDATE
ON Z_journal FOR EACH ROW
DECLARE
 v_articleCount INT := 0;
BEGIN
    IF INSERTING OR UPDATING THEN
        IF UPPER(:NEW.NAME) LIKE '%CZECH%' OR UPPER(:NEW.NAME) LIKE '%SLOVAK%' THEN
            IF UPPER(:NEW.czech_or_slovak) = 'NE' THEN --pro jistotu i tady upper
                :NEW.czech_or_slovak := 'ANO';
            END IF;
        END IF;
    ELSIF DELETING THEN
        SELECT COUNT(aid) INTO v_articleCount FROM Z_article WHERE jid = :OLD.jid;
        IF v_articleCount != 0 THEN
            raise_application_error(-20015,'Nelze smazat aktivni casopis');
            --nevim jestli tohle je uz ten blok ale jako raise_application_error je prece ta brzda tak by mohl byt 
            -- ale i ze zvedavosti jak v triggeru necemu zabranit at je to cokoliv z tech 3 moznosti? staci return?
        END IF;
    END IF;
    
END;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

-- ==============================================================================
-- TÉMA 1: PROCEDURY, TRANSAKCE A ODCHYTÁVÁNÍ CHYB (NO_DATA_FOUND)
-- ==============================================================================

-- Příprava pracovních tabulek (CTAS - Create Table As Select)
-- POZOR: CTAS kopíruje data a strukturu, ale NEKOPÍRUJE primární/cizí klíče a indexy!
CREATE TABLE work_z_institution AS SELECT * FROM z_institution;
CREATE TABLE work_z_article_institution AS SELECT * FROM z_article_institution;

-- Vytvoření procedury
CREATE OR REPLACE PROCEDURE P_DeleteInstitutionByName (p_inst_name VARCHAR2)
AS
    -- V PL/SQL se VŠECHNY proměnné musí deklarovat zde nahoře, před BEGIN.
    p_iid int := NULL;
    v_Deleted INT;
BEGIN
    -- 1. Validace vstupních parametrů
    IF p_inst_name IS NULL THEN
        dbms_output.put_line('NULL PARAM');
        RETURN; -- Okamžité ukončení procedury, kód dál nepokračuje
    END IF;

    -- 2. Získání ID (Klíčový krok)
    -- V PL/SQL musí mít každý SELECT klauzuli INTO!
    -- Pokud se nenajde žádný řádek, nevyplní se NULL, ale vystřelí výjimka NO_DATA_FOUND.
    SELECT iid INTO p_iid
    FROM work_z_institution 
    WHERE name = p_inst_name;
    
    -- 3. Transakční mazání (odspodu - nejdřív vazby, pak rodič)
    DELETE FROM work_z_article_institution WHERE iid = p_iid;
    
    -- FÍGL: SQL%ROWCOUNT vrací počet řádků ovlivněných bezprostředně předcházejícím příkazem (DML)
    v_deleted := SQL%ROWCOUNT; 
    
    DELETE FROM work_z_institution WHERE iid = p_iid;
    
    -- 4. Výpisy a potvrzení transakce
    -- Drobné textové úpravy podle vzoru ze zadání (byla, dvojtečka, tečky)
    dbms_output.put_line('Instituce '||p_inst_name||' byla uspesne smazana.');
    dbms_output.put_line('Odstraneno zaznamu z vazebni tabulky: '||v_Deleted||'.');
    
    -- Zapsání změn do databáze
    COMMIT; 

-- 5. Ošetření chyb (Exception Handling)
EXCEPTION
    -- Odchycení situace, kdy SELECT INTO nenašel instituci
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('Instituce '||p_inst_name||' neexistuje.');
    
    -- Odchycení jakékoliv jiné nečekané chyby
    WHEN OTHERS THEN
        dbms_output.put_line('Chyba pri mazani');
        ROLLBACK; -- Zrušení všech DML operací od posledního COMMITu
END;
/ -- Lomítko na konci se v Oracle používá pro spuštění kompilace PL/SQL bloku!

-- ==============================================================================
-- Testovací blok pro proceduru
-- ==============================================================================
BEGIN 
    P_DeleteInstitutionByName('METCENAS o.p.s.');
END;
/

-- ==============================================================================
-- TÉMA 2: TRIGGERY (SPOUŠTĚČE), AUDITOVÁNÍ A UŽIVATELSKÉ VÝJIMKY
-- ==============================================================================

-- Příprava tabulek
CREATE TABLE work_z_author AS SELECT * FROM z_author;

-- Logovací tabulka stavěná na zelené louce. 
-- V čistém CREATE TABLE (mimo PL/SQL) nefunguje %type, musí se psát datové typy natvrdo.
CREATE TABLE work_z_author_name_changes(
    rid int NOT NULL,
    old_name VARCHAR2(255) NOT NULL,
    new_name VARCHAR2(255) NOT NULL,
    change_time TIMESTAMP NOT NULL
);

-- Tvorba Triggeru
-- Spustí se až PO (AFTER) updatu, a to pouze nad sloupcem 'name'
CREATE OR REPLACE TRIGGER TR_AuthorNameAudit
AFTER UPDATE OF name ON work_z_author
FOR EACH ROW -- Kritické: zajišťuje, že máme přístup k proměnným :OLD a :NEW pro každý upravovaný řádek!
DECLARE 
    v_article_count int;
BEGIN
    -- Číst data můžeme přímo z originálních (ne-work) tabulek.
    -- :OLD.rid obsahuje ID autora z upravovaného řádku (před úpravou).
    SELECT COUNT(aid) INTO v_article_count 
    FROM z_article_author 
    WHERE rid = :OLD.rid;

    -- Podmínka ze zadání: logovat jen autory s více než 5 články
    IF v_article_count > 5 THEN
        INSERT INTO work_z_author_name_changes VALUES (
            :OLD.rid,
            :OLD.name,   -- Jméno před úpravou
            :NEW.name,   -- Nové jméno, které tam uživatel posílá
            SYSTIMESTAMP -- Funkce pro zjištění aktuálního data a času
        );
        
        -- Volitelný výpis do konzole (v praxi u triggerů opatrně, pokud by se updatovalo 1000 řádků, vypíše to 1000x)
        dbms_output.put_line('Name_changes_recorded: '||SQL%ROWCOUNT);
    END IF;

EXCEPTION 
    WHEN OTHERS THEN
        -- raise_application_error zruší probíhající UPDATE a vyhodí chybu aplikaci.
        -- Číslo musí být v rozsahu -20000 až -20999.
        raise_application_error(-20000, 'Chyba pri auditovani jmena');
END;
/

-- ==============================================================================
-- Testovací script pro Trigger
-- ==============================================================================
UPDATE work_z_author SET name = 'Sharma, A. TEST' WHERE rid = 3604;
COMMIT;

SELECT * FROM work_z_author_name_changes;
SELECT * FROM work_z_author_name_changes;



DROP TABLE work_z_author
CREATE  TABLE work_z_author as SELECT * FROM z_author;
CREATE TABLE work_z_article_author AS SELECT * FROM Z_article_author;

CREATE PROCEDURE P_DeleteAuthorByName(p_author_name VARCHAR2) 
      AS
        v_author_id int := NULL;
        v_rows_count int := NULL;
      BEGIN
        IF p_author_name IS NULL THEN
            dbms_output.put_line('NULL PARAMETER');
            RETURN;-- jaky je rozdil mezi timto a ROLLBACK; neni return jen vec funkci nebylo by tady validnejsi dat rollback?
        END IF;
        SELECT rid INTO v_author_id FROM work_z_author WHERE name = p_author_name;
        DELETE FROM work_z_article_author WHERE rid = v_author_id;
        v_rows_count :=  SQL%ROWCOUNT; 
        DELETE FROM work_z_author WHERE rid = v_author_id;
                dbms_output.put_line('Autor '||p_author_name||' uspesne smazan.');
                dbms_output.put_line('Odstraneno zaznamu z  vazebni tabulky: '||v_rows_count);
        COMMIT;
        EXCEPTION 
             WHEN NO_DATA_FOUND THEN
                dbms_output.put_line('Autor '||p_author_name||' neexistuje');
                ROLLBACK;
            WHEN OTHERS THEN
            dbms_output.put_line('ERROR pri mazani');
                ROLLBACK;
      END;
      
      
SELECT * FROM work_z_article_author;
CREATE TABLE work_z_article AS SELECT * FROM z_article;
SELECT * FROM work_z_article;
--trigger spusteny pri delete bude logovat do tabulky work_z_article_deleted pouze clanky
--ktere maji 3 a mene autoru
-- TOHLE ZKOPIRUJE STRUKTURU TABULKY ALE NIC NEVLOZI
CREATE TABLE work_z_article_deleted AS SELECT * FROM work_z_article WHERE 1 = 0;

CREATE OR REPLACE TRIGGER TR_DeleteAudit
AFTER DELETE ON work_z_article
FOR EACH ROW
DECLARE
    v_authors_count INT;
    BEGIN 
        SELECT COUNT(rid) INTO v_authors_count 
        FROM work_z_article_author 
        WHERE aid = :OLD.aid;
        IF v_authors_count > 3 THEN
        RETURN;--ukoncim cely trigger jelikoz nechci ukladat ty s vice jak 3 clanky
        --udelal jsem to takhle schvalne naopak nez v predeslem triggeru kde jsem mel if
        --pro validni stav
        END IF;
        INSERT INTO work_z_article_deleted  VALUES (:OLD.aid ,
        :OLD.jid ,
        :OLD.ut_wos ,
        :OLD.type ,
        :OLD.name ,
        :OLD.year ,
        :OLD.author_count);
                dbms_output.put_line('MAZANY RADEK'||:OLD.aid ||' '||
        :OLD.jid ||' '||
        :OLD.ut_wos ||' '||
        :OLD.name ||' '||
        :OLD.year ||' '||
        :OLD.type ||' '||
        :OLD.author_count);
        EXCEPTION 
            WHEN OTHERS THEN
                raise_application_error(-2001,'CHYBA PRI AUDITOVANI MAZANYCH CLANKU');
    END;

SELECT * FROM work_z_article;
DELETE FROM work_z_article WHERE aid = 2;




-- Napiste ulozenou funkci CreateArticleYear s parametrem p_year int, 
-- ktera vytvori tabulku z_article_year se stejnou strukturou, jako ma 
-- tabulka z_article, az na novy atribut last_update datoveho typu date
-- (hodnota nemuze byt null). Primarni a cizi klice musi byt stejne jako
-- v puvodni tabulce.
--
-- Do nove tabulky zkopirujete, jednim prikazem SQL, zaznamy clanku z 
-- roku p_year z tabulky z_article (v dynamickem SQL pouzijete vazane 
-- promenne pokud je to mozne). Hodnota atributu last_update bude nastavena 
-- na aktualni datum.
--
-- Jednim prikazem SQL zjistite pocet zaznamu nove tabulky, tento pocet 
-- pak bude funkce vracet.
--
-- Pred ukoncenim funkce zrusite tabulku.
--
-- V miste volani funkce vypisete navratovou hodnotu funkce. Budete testovat
-- pro dva roky tak, aby v jednom roce byl pocet zaznamu 0 a ve druhem roce 
-- byl pocet zaznamu nenulovy.

CREATE OR REPLACE FUNCTION CreateArticleYear(p_year int) 
          RETURN INT
          AS
            v_sql VARCHAR(2000);
            v_ret int :=0;
          BEGIN
            v_sql := 'CREATE TABLE z_article_year AS SELECT a.*, SYSDATE AS last_update
                                                        FROM z_article a
                                                        WHERE YEAR = '||p_year;
            EXECUTE IMMEDIATE v_sql;
            v_sql :='ALTER TABLE z_article_year ADD CONSTRAINT
                        z_pk_aid PRIMARY KEY(aid)';
            EXECUTE IMMEDIATE v_sql;
            
            v_sql :='ALTER TABLE z_article_year ADD CONSTRAINT fk_to_z_journal FOREIGN KEY(jid)
                        REFERENCES z_journal(jid)';
            
            EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM z_article_year' INTO v_ret;
            EXECUTE IMMEDIATE 'DROP TABLE z_article_year';
            COMMIT;
            RETURN v_ret;
            EXCEPTION
                WHEN OTHERS THEN
                        dbms_output.put_line('chyba');

          END;
       
       DROP TABLE z_article_year;
BEGIN
    dbms_output.put_line('clanku napsanych v roce 2021: '||CreateArticleYear(2021));
END;
--procedura vytvori nebo obnovi tabulku town_institution_stats obsahujici pro kazde mesto
--pocet jeho instituci.

CREATE OR REPLACE PROCEDURE p_buildTownInstitutionStats(p_mode VARCHAR2)
AS
    v_table_exists int := 0;
    v_sql VARCHAR(2000);
    c_table CONSTANT VARCHAR2(50) := 'TOWN_INSTITUTION_STATS';
    ex_table_already_exists EXCEPTION;
BEGIN
    -- 1. Validace parametrů
    IF p_mode IS NULL OR p_mode NOT IN ('CREATE','REPLACE') THEN
        raise_application_error(-20000, 'Chyba spatna hodnota parametru');
        -- Zde RETURN nepotřebuješ, raise_application_error proceduru ukončí sama
    END IF;

    -- 2. Zjištění existence tabulky (Zde vázaná proměnná funguje - je to DML select)
    v_sql := 'SELECT COUNT(*) FROM user_tables WHERE table_name = :t_name';
    EXECUTE IMMEDIATE v_sql INTO v_table_exists USING c_table;
        dbms_output.put_line('KONTROLA EXISTENCE DOKONCENO'); 

    
    -- 3. Rozhodovací logika podle p_mode
    IF p_mode = 'CREATE' THEN
        IF v_table_exists > 0 THEN
            RAISE ex_table_already_exists;
        END IF;
        
    ELSIF p_mode = 'REPLACE' THEN -- Pozor: ELSIF, nikoliv ELSE IF
        IF v_table_exists > 0 THEN
            -- DDL příkaz DROP nepodporuje bindování. Musíme lepit (||)
            v_sql := 'DROP TABLE ' || c_table;
            EXECUTE IMMEDIATE v_sql;
            dbms_output.put_line('SMAZANI DOKONCENO'); 
        END IF;
    END IF;

    -- 4. Vytvoření tabulky (Tohle se provede pro CREATE, pokud tabulka neexistovala, 
    -- nebo pro REPLACE, pokud se už úspěšně dropnula)
    -- U DDL opět žádné bindování, ale vzhledem k zadání tady název tabulky můžeme napsat natvrdo.
    v_sql := 'CREATE TABLE town_institution_stats AS 
                SELECT town, COUNT(*) AS institution_count 
                FROM z_INSTITUTION
                WHERE town IS NOT NULL
                GROUP BY town';
    EXECUTE IMMEDIATE v_sql; -- Zde chybělo spuštění!
    dbms_output.put_line('VYTVORENI TABULKY DOKONCENO'); 

    
EXCEPTION
    WHEN ex_table_already_exists THEN
        dbms_output.put_line('chyba: tabulka jiz existuje a parametr = CREATE');
    WHEN OTHERS THEN 
        ROLLBACK;
        -- Tohle nám konečně prozradí, na čem to padá!
        dbms_output.put_line('Neznama chyba: ' || SQLERRM); 
END;


    
CREATE OR REPLACE FUNCTION F_CountDistinctPerColumn(p_table_name VARCHAR2) 
          RETURN VARCHAR2
          IS
            v_ret VARCHAR2(2000):='';
            v_table_exist INT := 0;
            v_sql VARCHAR2(2000);
            distinct_count INT := 0;
            v_upper_parameter VARCHAR2(100);
            --nechapu kde psat to DECLARE
            v_col_name VARCHAR2(100); 
            CURSOR c_columns_names IS 
            SELECT column_name 
            FROM user_tab_columns 
            WHERE table_name = v_upper_parameter;
          BEGIN
            v_upper_parameter := UPPER(p_table_name);
            v_sql := 'SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME = :p_t_name';
            EXECUTE IMMEDIATE v_sql INTO v_table_exist USING v_upper_parameter;
            IF v_table_exist = 0 THEN
                dbms_output.put_line('TABULKA' || p_table_name||' NEEXISTUJE!!!'); 
                RETURN NULL;
            END IF;
        OPEN c_columns_names;
            LOOP
                FETCH c_columns_names INTO v_col_name;
                EXIT WHEN c_columns_names%NOTFOUND;
               v_sql := 'SELECT COUNT(DISTINCT ' || v_col_name || ') FROM ' || v_upper_parameter;
                EXECUTE IMMEDIATE v_sql INTO distinct_count; -- nemuze byt vazana
                v_ret := v_ret || v_col_name || '('||distinct_count||'), ';
            END LOOP;
        CLOSE c_columns_names;
        v_ret:=RTRIM(v_ret, ', ');
        RETURN v_ret;
        END F_COUNTDISTINCTPERCOLUMN;
        
BEGIN
    dbms_output.put_line( F_COUNTDISTINCTPERCOLUMN('Z_INSTITUTION')) ;
END;
CREATE OR REPLACE FUNCTION F_CountDistinctPerColumnFOR(p_table_name VARCHAR2) 
          RETURN VARCHAR2
          IS
            v_ret VARCHAR2(2000):='';
            v_table_exist INT := 0;
            v_sql VARCHAR2(2000);
            distinct_count INT := 0;
            v_upper_parameter VARCHAR2(100);
            CURSOR c_columns_names IS 
                                    SELECT column_name 
                                    FROM user_tab_columns 
                                    WHERE table_name = v_upper_parameter;
          BEGIN
            v_upper_parameter := UPPER(p_table_name);
            v_sql := 'SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME = :p_t_name';
            EXECUTE IMMEDIATE v_sql INTO v_table_exist USING v_upper_parameter;
            IF v_table_exist = 0 THEN
                dbms_output.put_line('TABULKA' || p_table_name||' NEEXISTUJE!!!'); 
                RETURN NULL;
            END IF;
            FOR one_col IN c_columns_names LOOP
                v_sql := 'SELECT COUNT(DISTINCT '|| one_col.column_name || ') FROM ' || v_upper_parameter;
                EXECUTE IMMEDIATE v_sql INTO distinct_count;
                v_ret := v_ret || one_col.column_name || '(' || distinct_count || '), ';
            END LOOP;
        v_ret:=RTRIM(v_ret, ', ');--right trim odrezani retezce zprava
        RETURN v_ret;
        END F_CountDistinctPerColumnFOR;

      
      
    BEGIN
    dbms_output.put_line( F_COUNTDISTINCTPERCOLUMNFOR('Z_INSTITUTION')) ;
END;

--p_set udava zda ma byt dany clanek prirazen autorovi
--zkontroluje relaci mezi p_rid a p_aid (author a article) v tabulce Article_author 
--pokud prirazuje tak se v tabulce Article inkrementuje author_count a naopak pri odebrani
--vrati I pokud bylo prirazeno a D pokud odebrani
--pokud nebyla uskutecnena zadna akce tak N
CREATE OR REPLACE FUNCTION F_SetArticleAuthors(p_aid INT,p_rid INT, p_set BOOLEAN) 
          RETURN CHAR
          IS
            v_author_asigned_to_article INT :=0;
          BEGIN
            SELECT COUNT(*) INTO v_author_asigned_to_article FROM z_article_author WHERE AID = p_aid AND RID = p_rid;
            IF (p_set = TRUE AND v_author_asigned_to_article !=0) OR 
            (p_set = FALSE AND v_author_asigned_to_article =0) THEN -- chceme priradit a uz je nebo chceme odebrat a uy je odebran
                RETURN 'N';
                
                --pridavame
            ELSIF p_set = TRUE THEN
                INSERT INTO z_article_author VALUES (p_aid,p_rid);
                UPDATE z_article SET author_count = author_count + 1 WHERE aid = p_aid;
                RETURN 'I';
                
                --ODEBIRAME
            ELSIF p_set = FALSE THEN
                DELETE FROM z_article_author WHERE  AID = p_aid AND RID = p_rid;
                UPDATE z_article SET author_count = author_count - 1 WHERE aid = p_aid;
                RETURN 'D';
            END IF;
            RETURN 'N';
            EXCEPTION 
                WHEN OTHERS THEN
                ROLLBACK;
                    dbms_output.put_line( 'CHYBAAAA!');
          END F_SetArticleAuthors;
          
        SELECT * FROM z_article;
        SELECT * FROM z_author;

            SELECT COUNT(*)  FROM z_article_author WHERE AID = 119 AND RID = 588;

BEGIN
    dbms_output.put_line(F_SetArticleAuthors(119,588,FALSE));
END  ;
      
purge recyclebin;
DROP TABLE WORK_Z_ARTICLE_AUTHOR;
DROP TABLE WORK_Z_ARTICLE;

-- Vytvoříme pidi-tabulku jen s 50 řádky
CREATE TABLE WORK_Z_ARTICLE_AUTHOR AS 
SELECT * FROM z_article_author WHERE ROWNUM <= 50;

-- A teď zkusíme ten tvůj dokonalý kód pro klíč:
ALTER TABLE WORK_Z_ARTICLE_AUTHOR ADD CONSTRAINT pk_work_article_author PRIMARY KEY (AID, RID);

CREATE TABLE WORK_Z_ARTICLE_AUTHOR AS SELECT * FROM z_article_author;
SELECT * FROM WORK_Z_ARTICLE_AUTHOR;
ALTER TABLE WORK_Z_ARTICLE_AUTHOR ADD CONSTRAINT pk_work_article_author PRIMARY KEY (AID, RID);

SELECT * FROM WORK_Z_ARTICLE;

ALTER TABLE WORK_Z_ARTICLE_AUTHOR ADD CONSTRAINT z_pk_aid PRIMARY KEY(aid);
CREATE OR REPLACE TRIGGER newTrigger
    AFTER INSERT OR UPDATE OR DELETE
    OF z_


-- procedura pro parametr rid vytvori tabulku record_rok pro kazdy rok ve kterem autor publikoval clanek
--v rekordu je id istituce clanku, celkovy pocet clanku v tom roce te instituce, kolik clanku napsal dany autor pro tu institci ten rok

CREATE OR REPLACE PROCEDURE P_authorYearRecord(p_rid INT)
      IS
          v_idInstitution INT :=0;
          v_articlesCountInstitution INT :=0;
          v_articleCountAuthor INT :=0;
          v_sql VARCHAR2(2000);
          v_countTables INT :=0;
      BEGIN
        FOR authorsActiveYears IN (SELECT DISTINCT a.year FROM Z_ARTICLE a LEFT JOIN
                                    z_ARTICLE_AUTHOR aa ON(aa.aid=a.aid)
                                    WHERE aa.rid = p_rid
        )LOOP
            SELECT COUNT(*) INTO v_countTables FROM USER_TABLES WHERE TABLE_NAME = UPPER('record_'||authorsActiveYears.year);
            IF v_countTables > 0 THEN
                v_sql := 'DROP TABLE RECORD_'||UPPER(authorsActiveYears.year);
                EXECUTE IMMEDIATE v_sql;
                dbms_output.put_line('TABULKA '||UPPER('record_'||authorsActiveYears.year)||' JIZ EXSTOVALA');
            END IF;
            v_sql :='CREATE TABLE RECORD_'||authorsActiveYears.year ||' (
                    iid INT PRIMARY KEY NOT NULL,
                    article_count INT default 0,
                    authors_articles_count INT default 0)';
                    EXECUTE IMMEDIATE v_sql;
                    dbms_output.put_line('TABULKA '||UPPER('record_'||authorsActiveYears.year)||' VYTVORENA');
                    
            v_sql := 'INSERT INTO RECORD_' || authorsActiveYears.year || ' (iid, article_count, authors_articles_count)
                      SELECT
                          ai.iid,
                          (SELECT COUNT(DISTINCT a2.aid)
                           FROM z_article a2 
                           JOIN z_article_institution ai2 ON (ai2.aid = a2.aid)
                           WHERE ai2.iid = ai.iid AND a2.year = :rok ),
                          COUNT(DISTINCT a.aid)
                      FROM z_article a
                      JOIN z_article_institution ai ON a.aid = ai.aid
                      JOIN z_article_author aa ON a.aid = aa.aid
                      WHERE aa.rid = :autor 
                        AND a.year = :rok2
                      GROUP BY ai.iid';
            
            EXECUTE IMMEDIATE v_sql USING authorsActiveYears.year, p_rid, authorsActiveYears.year;
                
        END LOOP;
      END P_authorYearRecord;

CREATE OR REPLACE PROCEDURE p_DropTablesLikeName(p_name VARCHAR2)
IS
    v_sql VARCHAR2(2000);
BEGIN
        FOR table_name_including_p_name IN (SELECT TABLE_NAME 
                                            FROM USER_TABLES
                                            WHERE TABLE_NAME LIKE UPPER(p_name))LOOP
                                            dbms_output.put_line(table_name_including_p_name.TABLE_NAME);
                                            DROP TABLE table_name_including_p_name.TABLE_NAME;
                                            END LOOP;
                                        
END;  
      



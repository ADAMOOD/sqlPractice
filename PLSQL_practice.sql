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

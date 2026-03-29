
## 1. Základy PL/SQL
* **Vždy `INTO`:** Uvnitř `BEGIN...END` nesmí být `SELECT` bez `INTO` (např. `SELECT sloupec INTO promenna`).
* **Syntaxe `ELSIF`:** Píše se zásadně dohromady (ne `ELSE IF`), jinak vyhodí chybu kompilace.
* **`RETURN` vs. `ROLLBACK`:** * `RETURN` okamžitě ukončí běh procedury/funkci.
    * `ROLLBACK` vrátí data zpět, ale **neukončí** proceduru (kód pod ním jede dál).
* **`SQL%ROWCOUNT`:** Systémová proměnná. Vrací počet řádků ovlivněných bezprostředně předchozím příkazem `INSERT`, `UPDATE` nebo `DELETE`.

## 2. Tabulky a Triggery
* **Kopie struktury bez dat:** `CREATE TABLE nova AS SELECT * FROM stara WHERE 1 = 0;`
* **CTAS ztrácí vazby:** `CREATE TABLE AS SELECT` přenese jen sloupce a data. **Nepřenáší** primární klíče, cizí klíče ani indexy.
* **Unikátní názvy Constraintů:** Názvy klíčů (např. `pk_moje_tabulka`) musí být unikátní v celém databázovém schématu, nejen v jedné tabulce.
* **Kde (ne)funguje `%type`:** Lze použít jen pro deklaraci proměnných v bloku PL/SQL. V DDL (např. `CREATE TABLE`) musíš psát typy natvrdo (např. `VARCHAR2(50)`).
* **Zápis starých hodnot v Triggeru:** Neexistuje zkratka `VALUES (:OLD)`. Sloupce se musí vypsat ručně: `VALUES (:OLD.id, :OLD.nazev)`.
* **Fyzické pořadí sloupců:** Pokud do `INSERTu` neuvedeš sloupce, databáze vkládá data podle reálného fyzického pořadí v DB. Vždy si udělej `SELECT *` na kontrolu struktury.

## 3. Dynamické SQL (`EXECUTE IMMEDIATE`)
* **Vázané proměnné (`USING`):**
    * **Pouze pro DML:** Fungují pro hodnoty dat (`SELECT`, `INSERT`, `UPDATE`, `DELETE`).
    * **Zákaz v DDL:** U názvů tabulek, sloupců nebo v příkazech `CREATE`/`DROP`/`ALTER` se musí stringy lepit natvrdo (přes `||`).
* **Chyba ORA-01745 (Rezervovaná slova):** Název vázané proměnné nesmí být SQL klíčové slovo. Nelze použít `:table`, použij např. `:t_name`.
* **Názvy objektů a velikost písmen:** Systémové pohledy (`user_tables`, `all_tables`) ukládají názvy **VELKÝMI PÍSMENY**. Dotaz musí hledat `'NAZEV_TABULKY'`.

## 4. Výjimky (Exceptions)
* **Tichý zabiják `WHEN OTHERS`:** Samotný `ROLLBACK` v tomto bloku chybu skryje. Pro ladění vždy přidej: `dbms_output.put_line(SQLERRM);`.
* **`COUNT()` nikdy nespadne:** Funkce `COUNT(*)` neháže `NO_DATA_FOUND`. Pokud nic nenajde, vrací `0`.
* **Uživatelské chyby:** `raise_application_error` přijímá pouze záporná čísla v rozsahu **-20000 až -20999**.

## 5. Datové modelování a Oracle specifika
* **Vztah 1:1 (Optional to Mandatory):** Podle logiky Oracle Academy patří Cizí klíč (FK) **vždy na povinnou stranu** (do Tabulky B).
* **Kompilační past s tabulkami:** Pokud skript procedurou vytvoří tabulku a hned další řádek na ni dělá `SELECT`, skript spadne při kompilaci (tabulka "neexistuje"). Volání procedury a následný `SELECT` musíš oddělit lomítkem `/`.

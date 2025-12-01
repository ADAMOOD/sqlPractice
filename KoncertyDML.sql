------------------------------------------------------
-- BANDS
------------------------------------------------------
INSERT INTO bands (name, formed_date, genre, bio, website)
VALUES
('Radiohead', '1985-01-01', 'Alternative Rock', 'English rock band from Abingdon, Oxfordshire.', 'https://www.radiohead.com'),
('Queen', '1970-01-01', 'Rock', 'Legendary British rock band formed in London.', 'https://www.queenonline.com'),
('Zrní', '2001-01-01', 'Alternative Folk', 'Czech alternative folk band from Kladno.', 'https://www.zrni.cz'),
('Kabát', '1983-01-01', 'Hard Rock', 'Czech rock band from Teplice.', 'https://www.kabat.cz');

------------------------------------------------------
-- MUSICIANS 
------------------------------------------------------

-- RADIOHEAD
INSERT INTO musicians (band_id, first_name, middle_name, last_name, role, joined_date)
VALUES
(1, 'Thom', NULL, 'Yorke', 'Vocals, Guitar', '1985-01-01'),
(1, 'Jonny', NULL, 'Greenwood', 'Lead Guitar, Keys', '1985-01-01'),
(1, 'Ed', NULL, 'OBrien', 'Guitar', '1985-01-01'),
(1, 'Colin', NULL, 'Greenwood', 'Bass', '1985-01-01'),
(1, 'Phil', NULL, 'Selway', 'Drums', '1985-01-01');

-- QUEEN
INSERT INTO musicians (band_id, first_name, middle_name, last_name, role, joined_date)
VALUES
(2, 'Freddie', NULL, 'Mercury', 'Vocals, Piano', '1970-01-01'),
(2, 'Brian', NULL, 'May', 'Guitar', '1970-01-01'),
(2, 'Roger', NULL, 'Taylor', 'Drums', '1970-01-01'),
(2, 'John', NULL, 'Deacon', 'Bass', '1971-01-01');

-- ZRNI
INSERT INTO musicians (band_id, first_name, middle_name, last_name, role, joined_date)
VALUES
(3, 'Jan', NULL, 'Uhlík', 'Vocals, Guitar', '2001-01-01'),
(3, 'Ondøej', NULL, 'Škoch', 'Violin', '2001-01-01'),
(3, 'Jan', NULL, 'Juklík', 'Drums', '2001-01-01'),
(3, 'Tomáš', NULL, 'Nìmec', 'Bass', '2001-01-01'),
(3, 'Filip', NULL, 'Zatloukal', 'Guitar', '2001-01-01');

-- KABAT
INSERT INTO musicians (band_id, first_name, middle_name, last_name, role, joined_date)
VALUES
(4, 'Josef', NULL, 'Vojtek', 'Vocals', '1988-01-01'),
(4, 'Tomáš', NULL, 'Krulich', 'Guitar', '1983-01-01'),
(4, 'Milan', NULL, 'Špalek', 'Bass', '1983-01-01'),
(4, 'Ota', NULL, 'Vojtek', 'Guitar', '1988-01-01'),
(4, 'Radek', NULL, 'Hron', 'Drums', '1990-01-01');

------------------------------------------------------
-- ALBUMS 
------------------------------------------------------

-- RADIOHEAD
INSERT INTO albums (band_id, title, release_date, label, album_type)
VALUES
(1, 'OK Computer', '1997-05-21', 'Parlophone', 'Album'),
(1, 'Kid A', '2000-10-02', 'Parlophone', 'Album');

-- QUEEN
INSERT INTO albums (band_id, title, release_date, label, album_type)
VALUES
(2, 'A Night at the Opera', '1975-11-21', 'EMI', 'Album'),
(2, 'The Works', '1984-02-27', 'EMI', 'Album');

-- ZRNI
INSERT INTO albums (band_id, title, release_date, label, album_type)
VALUES
(3, 'Soundtrack ke konci svìta', '2012-01-01', 'Indies Scope', 'Album'),
(3, 'Jiskøící', '2017-01-01', 'Indies Scope', 'Album');

-- KABÁT
INSERT INTO albums (band_id, title, release_date, label, album_type)
VALUES
(4, 'Èert na koze jel', '1991-01-01', 'Monitor', 'Album'),
(4, 'Dole v dole', '2003-10-10', 'EMI', 'Album');

------------------------------------------------------
-- SONGS 
------------------------------------------------------

-- OK COMPUTER
INSERT INTO songs (album_id, title, duration_seconds, track_number, composer)
VALUES
(1, 'Airbag', 280, 1, 'Radiohead'),
(1, 'Paranoid Android', 387, 2, 'Radiohead'),
(1, 'Karma Police', 260, 6, 'Radiohead');


-- A NIGHT AT THE OPERA
INSERT INTO songs (album_id, title, duration_seconds, track_number, composer)
VALUES
(3, 'Death on Two Legs', 225, 1, 'Freddie Mercury'),
(3, 'Youre My Best Friend', 170, 4, 'John Deacon'),
(3, 'Bohemian Rhapsody', 354, 11, 'Freddie Mercury');

-- ZRNI 
INSERT INTO songs (album_id, title, duration_seconds, track_number, composer)
VALUES
(5, 'Hýkal', 240, 1, 'Zrní'),
(6, 'Jiskøící raketa toto', 270, 2, 'Zrní');


-- KABÁT – Dole v dole
INSERT INTO songs (album_id, title, duration_seconds, track_number, composer)
VALUES
(7, 'Porcelánový prasata', 215, 1, 'Kabát'),
(7, 'Dole v dole', 250, 2, 'Kabát');

------------------------------------------------------
-- TOURS 
------------------------------------------------------

INSERT INTO tours (band_id, name, start_date, end_date, notes)
VALUES
(1, 'OK Computer Tour', '1997-06-01', '1998-08-01', 'World tour'),
(2, 'The Works Tour', '1984-02-01', '1985-05-15', 'Worldwide tour'),
(4, 'Corrida Tour', '2006-01-01', '2007-12-01', 'Czech Tour');

------------------------------------------------------
-- VENUES 
------------------------------------------------------

INSERT INTO venues (name, address, city, country, capacity, indoor, contact)
VALUES
('O2 Arena', 'Èeskomoravská 2345/17', 'Praha', 'Czech Republic', 18000, 1, 'info@o2arena.cz'),
('Wembley Stadium', 'Wembley', 'London', 'United Kingdom', 90000, 0, 'contact@wembley.co.uk'),
('Klub Futurum', 'Zborovská 7', 'Praha', 'Czech Republic', 800, 1, 'info@futurum.cz');

------------------------------------------------------
-- CONCERTS 
------------------------------------------------------

INSERT INTO concerts (band_id, tour_id, venue_id, concert_date, ticket_price, attendance, notes)
VALUES
(1, 1, 2, '1997-09-15', 45.00, 65000, 'Radiohead at Wembley'),
(2, 2, 2, '1985-07-13', 50.00, 72000, 'Queen at Live Aid'),
(4, 3, 1, '2007-05-12', 30.00, 17000, 'Kabát Corrida Tour');

------------------------------------------------------
-- SETLIST SONGS 
------------------------------------------------------

-- Radiohead – Paranoid Android at Wembley
INSERT INTO setlist_songs (song_id, concert_id, position, played, actual_duration_seconds, notes)
VALUES
(2, 1, 1, 1, 395, 'Extended outro');

-- Queen – Bohemian Rhapsody at Live Aid 1985
INSERT INTO setlist_songs (song_id, concert_id, position, played, actual_duration_seconds, notes)
VALUES
(6, 2, 3, 1, 360, 'Iconic performance');

-- Kabát – Dole v dole at O2 Arena
INSERT INTO setlist_songs (song_id, concert_id, position, played, actual_duration_seconds, notes)
VALUES
(10, 3, 1, 1, 260, 'Opening song');



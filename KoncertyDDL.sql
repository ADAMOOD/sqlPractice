CREATE TABLE [bands] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [name] varchar(200) UNIQUE NOT NULL,
  [formed_date] date,
  [genre] varchar(100),
  [bio] text,
  [website] varchar(255)
)
GO

CREATE TABLE [musicians] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [band_id] int NOT NULL,
  [first_name] varchar(200) NOT NULL,
  [middle_name] varchar(200),
  [last_name] varchar(200) NOT NULL,
  [role] varchar(100),
  [joined_date] date
)
GO

CREATE TABLE [albums] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [band_id] int NOT NULL,
  [title] varchar(250) NOT NULL,
  [release_date] date,
  [label] varchar(150),
  [album_type] varchar(20) DEFAULT 'Album'
)
GO

CREATE TABLE [songs] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [album_id] int,
  [title] varchar(250) NOT NULL,
  [duration_seconds] int,
  [track_number] int,
  [composer] varchar(200)
)
GO

CREATE TABLE [tours] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [band_id] int NOT NULL,
  [name] varchar(200) NOT NULL,
  [start_date] date,
  [end_date] date,
  [notes] text
)
GO

CREATE TABLE [venues] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [name] varchar(250) NOT NULL,
  [address] varchar(300),
  [city] varchar(120),
  [country] varchar(120),
  [capacity] int,
  [indoor] bit DEFAULT (1),    -- TRUE
  [contact] varchar(200)
);
GO

CREATE TABLE [concerts] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [band_id] int NOT NULL,
  [tour_id] int,
  [venue_id] int NOT NULL,
  [concert_date] datetime2 NOT NULL DEFAULT GETDATE(),
  [ticket_price] numeric(8,2),
  [attendance] int,
  [notes] text
);
GO


CREATE TABLE [setlist_songs] (
  [song_id] int NOT NULL,
  [concert_id] int NOT NULL,
  [position] int NOT NULL,
  [played] bit DEFAULT (1), --TRUE
  [actual_duration_seconds] int,
  [notes] text,
  PRIMARY KEY ([song_id], [concert_id], [position])
)
GO

ALTER TABLE [musicians] 
ADD CONSTRAINT FK_musicians_band_id_bands
FOREIGN KEY ([band_id]) REFERENCES [bands] ([id]);
GO

ALTER TABLE [albums]
ADD CONSTRAINT FK_albums_band_id_bands
FOREIGN KEY ([band_id]) REFERENCES [bands] ([id]);
GO

ALTER TABLE [songs]
ADD CONSTRAINT FK_songs_album_id_albums
FOREIGN KEY ([album_id]) REFERENCES [albums] ([id]);
GO

ALTER TABLE [tours]
ADD CONSTRAINT FK_tours_band_id_bands
FOREIGN KEY ([band_id]) REFERENCES [bands] ([id]);
GO

ALTER TABLE [concerts]
ADD CONSTRAINT FK_concerts_band_id_bands
FOREIGN KEY ([band_id]) REFERENCES [bands] ([id]);
GO

ALTER TABLE [concerts]
ADD CONSTRAINT FK_concerts_tour_id_tours
FOREIGN KEY ([tour_id]) REFERENCES [tours] ([id]);
GO

ALTER TABLE [concerts]
ADD CONSTRAINT FK_concerts_venue_id_venues
FOREIGN KEY ([venue_id]) REFERENCES [venues] ([id]);
GO

ALTER TABLE [setlist_songs]
ADD CONSTRAINT FK_setlist_songs_song_id_songs
FOREIGN KEY ([song_id]) REFERENCES [songs] ([id]);
GO

ALTER TABLE [setlist_songs]
ADD CONSTRAINT FK_setlist_songs_concert_id_concerts
FOREIGN KEY ([concert_id]) REFERENCES [concerts] ([id]);
GO


-- =============================================
-- SELECT ALL CONSTRAINTS
-- =============================================
SELECT 
    fk.name AS FK_name,
    tp.name AS ParentTable,
    cp.name AS ParentColumn,
    tr.name AS ReferencedTable,
    cr.name AS ReferencedColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables tp 
    ON fkc.parent_object_id = tp.object_id
JOIN sys.columns cp 
    ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
JOIN sys.tables tr 
    ON fkc.referenced_object_id = tr.object_id
JOIN sys.columns cr 
    ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
WHERE tp.name IN ('musicians','albums','songs','tours','concerts','venues','setlist_songs','bands')
   OR tr.name IN ('musicians','albums','songs','tours','concerts','venues','setlist_songs','bands')
ORDER BY FK_name;


-- =============================================
-- DROP FOREIGN KEYS
-- =============================================
ALTER TABLE setlist_songs DROP CONSTRAINT FK_setlist_songs_song_id_songs;
ALTER TABLE setlist_songs DROP CONSTRAINT FK_setlist_songs_concert_id_concerts;

ALTER TABLE concerts DROP CONSTRAINT FK_concerts_band_id_bands;
ALTER TABLE concerts DROP CONSTRAINT FK_concerts_tour_id_tours;
ALTER TABLE concerts DROP CONSTRAINT FK_concerts_venue_id_venues;

ALTER TABLE tours DROP CONSTRAINT FK_tours_band_id_bands;

ALTER TABLE songs DROP CONSTRAINT FK_songs_album_id_albums;

ALTER TABLE albums DROP CONSTRAINT FK_albums_band_id_bands;

ALTER TABLE musicians DROP CONSTRAINT FK_musicians_band_id_bands;
GO


-- =============================================
-- DROP TABLES
-- =============================================

DROP TABLE IF EXISTS setlist_songs;
DROP TABLE IF EXISTS concerts;
DROP TABLE IF EXISTS venues;
DROP TABLE IF EXISTS tours;
DROP TABLE IF EXISTS songs;
DROP TABLE IF EXISTS albums;
DROP TABLE IF EXISTS musicians;
DROP TABLE IF EXISTS bands;
GO
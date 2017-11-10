BEGIN TRANSACTION;
CREATE TABLE VideoTrack(id_track INTEGER PRIMARY KEY AUTOINCREMENT,codec TEXT,width UNSIGNED INTEGER,height UNSIGNED INTEGER,fps FLOAT,media_id UNSIGNED INT,language TEXT,description TEXT,FOREIGN KEY ( media_id ) REFERENCES Media(id_media) ON DELETE CASCADE);
CREATE TABLE ShowEpisode(id_episode INTEGER PRIMARY KEY AUTOINCREMENT,media_id UNSIGNED INTEGER NOT NULL,artwork_mrl TEXT,episode_number UNSIGNED INT,title TEXT,season_number UNSIGNED INT,episode_summary TEXT,tvdb_id TEXT,show_id UNSIGNED INT,FOREIGN KEY(media_id) REFERENCES Media(id_media) ON DELETE CASCADE,FOREIGN KEY(show_id) REFERENCES Show(id_show) ON DELETE CASCADE);
CREATE TABLE Show(id_show INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT, release_date UNSIGNED INTEGER,short_summary TEXT,artwork_mrl TEXT,tvdb_id TEXT);
CREATE TABLE Settings(db_model_version UNSIGNED INTEGER NOT NULL DEFAULT 3);
INSERT INTO `Settings` VALUES (4);
CREATE TABLE PlaylistMediaRelation(media_id INTEGER,playlist_id INTEGER,position INTEGER,PRIMARY KEY(media_id, playlist_id),FOREIGN KEY(media_id) REFERENCES Media(id_media) ON DELETE CASCADE,FOREIGN KEY(playlist_id) REFERENCES Playlist(id_playlist) ON DELETE CASCADE);
CREATE VIRTUAL TABLE PlaylistFts USING FTS3(name);
CREATE TABLE Playlist(id_playlist INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT UNIQUE,creation_date UNSIGNED INT NOT NULL);
CREATE TABLE Movie(id_movie INTEGER PRIMARY KEY AUTOINCREMENT,media_id UNSIGNED INTEGER NOT NULL,title TEXT UNIQUE ON CONFLICT FAIL,summary TEXT,artwork_mrl TEXT,imdb_id TEXT,FOREIGN KEY(media_id) REFERENCES Media(id_media) ON DELETE CASCADE);
CREATE TABLE MediaMetadata(id_media INTEGER,type INTEGER,value TEXT,PRIMARY KEY (id_media, type));
CREATE VIRTUAL TABLE MediaFts USING FTS3(title,labels);
CREATE TABLE MediaArtistRelation(media_id INTEGER NOT NULL,artist_id INTEGER,PRIMARY KEY (media_id, artist_id),FOREIGN KEY(media_id) REFERENCES Media(id_media) ON DELETE CASCADE,FOREIGN KEY(artist_id) REFERENCES Artist(id_artist) ON DELETE CASCADE);
CREATE TABLE Media(id_media INTEGER PRIMARY KEY AUTOINCREMENT,type INTEGER,subtype INTEGER,duration INTEGER DEFAULT -1,play_count UNSIGNED INTEGER,last_played_date UNSIGNED INTEGER,insertion_date UNSIGNED INTEGER,release_date UNSIGNED INTEGER,thumbnail TEXT,title TEXT COLLATE NOCASE,filename TEXT,is_favorite BOOLEAN NOT NULL DEFAULT 0,is_present BOOLEAN NOT NULL DEFAULT 1);
CREATE TABLE LabelFileRelation(label_id INTEGER,media_id INTEGER,PRIMARY KEY (label_id, media_id),FOREIGN KEY(label_id) REFERENCES Label(id_label) ON DELETE CASCADE,FOREIGN KEY(media_id) REFERENCES Media(id_media) ON DELETE CASCADE);
CREATE TABLE Label(id_label INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE ON CONFLICT FAIL);
CREATE TABLE History(id_media INTEGER PRIMARY KEY,insertion_date UNSIGNED INT NOT NULL,FOREIGN KEY (id_media) REFERENCES Media(id_media) ON DELETE CASCADE);
CREATE VIRTUAL TABLE GenreFts USING FTS3(name);
CREATE TABLE Genre(id_genre INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT UNIQUE ON CONFLICT FAIL,nb_tracks INTEGER NOT NULL DEFAULT 0);
CREATE TABLE Folder(id_folder INTEGER PRIMARY KEY AUTOINCREMENT,path TEXT,parent_id UNSIGNED INTEGER,is_blacklisted BOOLEAN NOT NULL DEFAULT 0,device_id UNSIGNED INTEGER,is_present BOOLEAN NOT NULL DEFAULT 1,is_removable BOOLEAN NOT NULL,FOREIGN KEY (parent_id) REFERENCES Folder(id_folder) ON DELETE CASCADE,FOREIGN KEY (device_id) REFERENCES Device(id_device) ON DELETE CASCADE,UNIQUE(path, device_id) ON CONFLICT FAIL);
CREATE TABLE File(id_file INTEGER PRIMARY KEY AUTOINCREMENT,media_id INT NOT NULL,mrl TEXT,type UNSIGNED INTEGER,last_modification_date UNSIGNED INT,size UNSIGNED INT,parser_step INTEGER NOT NULL DEFAULT 0,parser_retries INTEGER NOT NULL DEFAULT 0,folder_id UNSIGNED INTEGER,is_present BOOLEAN NOT NULL DEFAULT 1,is_removable BOOLEAN NOT NULL,is_external BOOLEAN NOT NULL,FOREIGN KEY (media_id) REFERENCES Media(id_media) ON DELETE CASCADE,FOREIGN KEY (folder_id) REFERENCES Folder(id_folder) ON DELETE CASCADE,UNIQUE( mrl, folder_id ) ON CONFLICT FAIL);
CREATE TABLE Device(id_device INTEGER PRIMARY KEY AUTOINCREMENT,uuid TEXT UNIQUE ON CONFLICT FAIL,scheme TEXT,is_removable BOOLEAN,is_present BOOLEAN);
CREATE TABLE AudioTrack(id_track INTEGER PRIMARY KEY AUTOINCREMENT,codec TEXT,bitrate UNSIGNED INTEGER,samplerate UNSIGNED INTEGER,nb_channels UNSIGNED INTEGER,language TEXT,description TEXT,media_id UNSIGNED INT,FOREIGN KEY ( media_id ) REFERENCES Media( id_media ) ON DELETE CASCADE);
CREATE VIRTUAL TABLE ArtistFts USING FTS3(name);
CREATE TABLE Artist(id_artist INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT COLLATE NOCASE UNIQUE ON CONFLICT FAIL,shortbio TEXT,artwork_mrl TEXT,nb_albums UNSIGNED INT DEFAULT 0,mb_id TEXT,is_present BOOLEAN NOT NULL DEFAULT 1);
INSERT INTO `Artist` VALUES (1,NULL,NULL,NULL,0,NULL,1);
INSERT INTO `Artist` VALUES (2,NULL,NULL,NULL,0,NULL,1);
CREATE TABLE AlbumTrack(id_track INTEGER PRIMARY KEY AUTOINCREMENT,media_id INTEGER,duration INTEGER NOT NULL,artist_id UNSIGNED INTEGER,genre_id INTEGER,track_number UNSIGNED INTEGER,album_id UNSIGNED INTEGER NOT NULL,disc_number UNSIGNED INTEGER,is_present BOOLEAN NOT NULL DEFAULT 1,FOREIGN KEY (media_id) REFERENCES Media(id_media) ON DELETE CASCADE,FOREIGN KEY (artist_id) REFERENCES Artist(id_artist) ON DELETE CASCADE,FOREIGN KEY (genre_id) REFERENCES Genre(id_genre),FOREIGN KEY (album_id) REFERENCES Album(id_album)  ON DELETE CASCADE);
CREATE VIRTUAL TABLE AlbumFts USING FTS3(title,artist);
CREATE TABLE AlbumArtistRelation(album_id INTEGER,artist_id INTEGER,PRIMARY KEY (album_id, artist_id),FOREIGN KEY(album_id) REFERENCES Album(id_album) ON DELETE CASCADE,FOREIGN KEY(artist_id) REFERENCES Artist(id_artist) ON DELETE CASCADE);
CREATE TABLE Album(id_album INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT COLLATE NOCASE,artist_id UNSIGNED INTEGER,release_year UNSIGNED INTEGER,short_summary TEXT,artwork_mrl TEXT,nb_tracks UNSIGNED INTEGER DEFAULT 0,duration UNSIGNED INTEGER NOT NULL DEFAULT 0,is_present BOOLEAN NOT NULL DEFAULT 1,FOREIGN KEY( artist_id ) REFERENCES Artist(id_artist) ON DELETE CASCADE);
CREATE INDEX video_track_media_idx ON VideoTrack(media_id);
CREATE INDEX show_episode_media_show_idx ON ShowEpisode(media_id, show_id);
CREATE INDEX parent_folder_id_idx ON Folder (parent_id);
CREATE INDEX movie_media_idx ON Movie(media_id);
CREATE INDEX index_last_played_date ON Media(last_played_date DESC);
CREATE INDEX folder_device_id_idx ON Folder (device_id);
CREATE INDEX file_media_id_index ON File(media_id);
CREATE INDEX file_folder_id_index ON File(folder_id);
CREATE INDEX audio_track_media_idx ON AudioTrack(media_id);
CREATE INDEX album_media_artist_genre_album_idx ON AlbumTrack(media_id, artist_id, genre_id, album_id);
CREATE INDEX album_artist_id_idx ON Album(artist_id);
CREATE TRIGGER update_playlist_order_on_insert AFTER INSERT ON PlaylistMediaRelation WHEN new.position IS NOT NULL BEGIN UPDATE PlaylistMediaRelation SET position = position + 1 WHERE playlist_id = new.playlist_id AND position = new.position AND media_id != new.media_id; END;
CREATE TRIGGER update_playlist_order AFTER UPDATE OF position ON PlaylistMediaRelation BEGIN UPDATE PlaylistMediaRelation SET position = position + 1 WHERE playlist_id = new.playlist_id AND position = new.position AND media_id != new.media_id; END;
CREATE TRIGGER update_playlist_fts AFTER UPDATE OF name ON Playlist BEGIN UPDATE PlaylistFts SET name = new.name WHERE rowid = new.id_playlist; END;
CREATE TRIGGER update_media_title_fts AFTER UPDATE OF title ON Media BEGIN UPDATE MediaFts SET title = new.title WHERE rowid = new.id_media; END;
CREATE TRIGGER update_genre_on_track_deleted AFTER DELETE ON AlbumTrack WHEN old.genre_id IS NOT NULL BEGIN UPDATE Genre SET nb_tracks = nb_tracks - 1 WHERE id_genre = old.genre_id; DELETE FROM Genre WHERE nb_tracks = 0; END;
CREATE TRIGGER update_genre_on_new_track AFTER INSERT ON AlbumTrack WHEN new.genre_id IS NOT NULL BEGIN UPDATE Genre SET nb_tracks = nb_tracks + 1 WHERE id_genre = new.genre_id; END;
CREATE TRIGGER on_track_genre_changed AFTER UPDATE OF  genre_id ON AlbumTrack BEGIN UPDATE Genre SET nb_tracks = nb_tracks + 1 WHERE id_genre = new.genre_id; UPDATE Genre SET nb_tracks = nb_tracks - 1 WHERE id_genre = old.genre_id; DELETE FROM Genre WHERE nb_tracks = 0; END;
CREATE TRIGGER limit_nb_records AFTER INSERT ON History BEGIN DELETE FROM History WHERE id_media in (SELECT id_media FROM History ORDER BY insertion_date DESC LIMIT -1 OFFSET 20); END;
CREATE TRIGGER is_track_present AFTER UPDATE OF is_present ON Media BEGIN UPDATE AlbumTrack SET is_present = new.is_present WHERE media_id = new.id_media; END;
CREATE TRIGGER is_folder_present AFTER UPDATE OF is_present ON Folder BEGIN UPDATE File SET is_present = new.is_present WHERE folder_id = new.id_folder; END;
CREATE TRIGGER is_device_present AFTER UPDATE OF is_present ON Device BEGIN UPDATE Folder SET is_present = new.is_present WHERE device_id = new.id_device; END;
CREATE TRIGGER is_album_present AFTER UPDATE OF is_present ON AlbumTrack BEGIN  UPDATE Album SET is_present=(SELECT COUNT(id_track) FROM AlbumTrack WHERE album_id=new.album_id AND is_present=1) WHERE id_album=new.album_id; END;
CREATE TRIGGER insert_playlist_fts AFTER INSERT ON Playlist BEGIN INSERT INTO PlaylistFts(rowid, name) VALUES(new.id_playlist, new.name); END;
CREATE TRIGGER insert_media_fts AFTER INSERT ON Media BEGIN INSERT INTO MediaFts(rowid,title,labels) VALUES(new.id_media, new.title, ''); END;
CREATE TRIGGER insert_genre_fts AFTER INSERT ON Genre BEGIN INSERT INTO GenreFts(rowid,name) VALUES(new.id_genre, new.name); END;
CREATE TRIGGER insert_artist_fts AFTER INSERT ON Artist WHEN new.name IS NOT NULL BEGIN INSERT INTO ArtistFts(rowid,name) VALUES(new.id_artist, new.name); END;
CREATE TRIGGER insert_album_fts AFTER INSERT ON Album WHEN new.title IS NOT NULL BEGIN INSERT INTO AlbumFts(rowid, title) VALUES(new.id_album, new.title); END;
CREATE TRIGGER has_files_present AFTER UPDATE OF is_present ON File BEGIN  UPDATE Media SET is_present=(SELECT COUNT(id_file) FROM File WHERE media_id=new.media_id AND is_present=1) WHERE id_media=new.media_id; END;
CREATE TRIGGER has_album_remaining AFTER DELETE ON Album WHEN old.artist_id IS NOT NULL AND old.artist_id != 1 AND old.artist_id != 2 BEGIN UPDATE Artist SET nb_albums = nb_albums - 1 WHERE id_artist = old.artist_id; DELETE FROM Artist WHERE id_artist = old.artist_id AND nb_albums = 0; END;
CREATE TRIGGER has_album_present AFTER UPDATE OF is_present ON Album BEGIN  UPDATE Artist SET is_present=(SELECT COUNT(id_album) FROM Album WHERE artist_id=new.artist_id AND is_present=1) WHERE id_artist=new.artist_id; END;
CREATE TRIGGER delete_playlist_fts BEFORE DELETE ON Playlist BEGIN DELETE FROM PlaylistFts WHERE rowid = old.id_playlist; END;
CREATE TRIGGER delete_media_fts BEFORE DELETE ON Media BEGIN DELETE FROM MediaFts WHERE rowid = old.id_media; END;
CREATE TRIGGER delete_label_fts BEFORE DELETE ON Label BEGIN UPDATE MediaFts SET labels = TRIM(REPLACE(labels, old.name, '')) WHERE labels MATCH old.name; END;
CREATE TRIGGER delete_genre_fts BEFORE DELETE ON Genre BEGIN DELETE FROM GenreFts WHERE rowid = old.id_genre; END;
CREATE TRIGGER delete_artist_fts BEFORE DELETE ON Artist WHEN old.name IS NOT NULL BEGIN DELETE FROM ArtistFts WHERE rowid=old.id_artist; END;
CREATE TRIGGER delete_album_track AFTER DELETE ON AlbumTrack BEGIN  UPDATE Album SET nb_tracks = nb_tracks - 1, duration = duration - old.duration WHERE id_album = old.album_id; DELETE FROM Album WHERE id_album=old.album_id AND nb_tracks = 0; END;
CREATE TRIGGER delete_album_fts BEFORE DELETE ON Album WHEN old.title IS NOT NULL BEGIN DELETE FROM AlbumFts WHERE rowid = old.id_album; END;
CREATE TRIGGER cascade_file_deletion AFTER DELETE ON File BEGIN  DELETE FROM Media WHERE (SELECT COUNT(id_file) FROM File WHERE media_id=old.media_id) = 0 AND id_media=old.media_id; END;
CREATE TRIGGER append_new_playlist_record AFTER INSERT ON PlaylistMediaRelation WHEN new.position IS NULL BEGIN  UPDATE PlaylistMediaRelation SET position = (SELECT COUNT(media_id) FROM PlaylistMediaRelation WHERE playlist_id = new.playlist_id) WHERE playlist_id=new.playlist_id AND media_id = new.media_id; END;
CREATE TRIGGER add_album_track AFTER INSERT ON AlbumTrack BEGIN UPDATE Album SET duration = duration + new.duration, nb_tracks = nb_tracks + 1 WHERE id_album = new.album_id; END;
COMMIT;

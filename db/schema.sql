DROP OWNED BY CURRENT_USER;

CREATE TABLE games (
	game text PRIMARY KEY,
	min_players integer,
	max_players integer,
	owner text[],
	base_time integer,
	time_per_player integer
);

CREATE TEMPORARY TABLE games_import (
	game text PRIMARY KEY,
	min_players integer,
	max_players integer,
	owner text,
	base_time integer,
	time_per_player integer,
	tag1 text,
	tag2 text,
	tag3 text,
	tag4 text,
	theme1 text,
	theme2 text
);

\copy games_import from 'gamelist.txt' (format csv, header)

INSERT INTO games
SELECT
	game,
	min_players,
	max_players,
	regexp_split_to_array(owner, ', '),
	base_time,
	time_per_player
FROM
	games_import
;

CREATE TABLE players (
	player text PRIMARY KEY,
	playing boolean NOT NULL DEFAULT TRUE,
	weight double precision NOT NULL DEFAULT 1,
	hashed_password text,
	autosave boolean NOT NULL DEFAULT TRUE,
	num_tables integer NOT NULL DEFAULT 1
);

INSERT INTO players VALUES
	('Brian', TRUE, 1),
	('Roland', TRUE, 1),
	('Ryan', TRUE, 1),
	('Sean', TRUE, 1),
	('Tony', TRUE, 1),
	('Mark', FALSE, 0),
	('Karen', FALSE, 0)
;

CREATE SERVER player_server FOREIGN DATA WRAPPER file_fdw;

CREATE TABLE player_votes (
	player text REFERENCES players,
	game text REFERENCES games,
	vote double precision,
	PRIMARY KEY (player, game)
);

\ir views.sql

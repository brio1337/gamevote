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

\copy games_import from 'seeds/gamelist.txt' (format csv, header)

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

INSERT INTO players VALUES
	('Brian', TRUE, 1),
	('Roland', TRUE, 1),
	('Ryan', TRUE, 1),
	('Sean', TRUE, 1),
	('Tony', TRUE, 1),
	('Mark', FALSE, 0)
;

CREATE SERVER player_server FOREIGN DATA WRAPPER file_fdw;

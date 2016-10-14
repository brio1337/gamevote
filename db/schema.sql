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
	hashed_password text
);

INSERT INTO players VALUES
	('Brian', true, 1, null),
	('Roland', true, 1, '$2a$10$qtZsvRtuJJ02QVpqb8V3uuiQE8iCdjPEmwiJOkJqFbKkTRWVQq9D6'),
	('Ryan', true, 1, '$2a$10$qtZsvRtuJJ02QVpqb8V3uuiQE8iCdjPEmwiJOkJqFbKkTRWVQq9D6'),
	('Sean', true, 1, '$2a$10$qtZsvRtuJJ02QVpqb8V3uuiQE8iCdjPEmwiJOkJqFbKkTRWVQq9D6'),
	('Tony', true, 1, '$2a$10$qtZsvRtuJJ02QVpqb8V3uuiQE8iCdjPEmwiJOkJqFbKkTRWVQq9D6'),
	('Mark', false, 0, '$2a$10$qtZsvRtuJJ02QVpqb8V3uuiQE8iCdjPEmwiJOkJqFbKkTRWVQq9D6'),
	('Karen', false, 0, '$2a$10$qtZsvRtuJJ02QVpqb8V3uuiQE8iCdjPEmwiJOkJqFbKkTRWVQq9D6')
;

CREATE VIEW players_playing AS
SELECT * FROM players WHERE playing;

CREATE VIEW player_groups AS
WITH RECURSIVE subgroups (player_list) AS (
	SELECT ARRAY[player] AS player_list FROM players_playing
	UNION ALL
	SELECT player_list || player
	FROM subgroups, players_playing
	WHERE player_list[array_upper(player_list, 1)] < player
		AND ((array_upper(player_list, 1) + 1) * 2 < (SELECT count(*) FROM players_playing) OR (
			(array_upper(player_list, 1) + 1) * 2 = (SELECT count(*) FROM players_playing)
			AND player_list[1] = (SELECT min(player) FROM players_playing))
		)
)
SELECT
	player_list AS player_group_1,
	(SELECT array_agg(player ORDER BY player) FROM players_playing WHERE player != ALL(player_list)) AS player_group_2
FROM subgroups
--WHERE array_upper(player_list, 1) >= 2
WHERE array_upper(player_list, 1) * 2 - (SELECT count(*) FROM players_playing) BETWEEN -1 AND 1
;

CREATE SERVER player_server FOREIGN DATA WRAPPER file_fdw;

CREATE TABLE player_votes (
	player text REFERENCES players,
	game text REFERENCES games,
	vote double precision,
	PRIMARY KEY (player, game)
);

CREATE VIEW player_scores AS
SELECT
	player,
	game,
	CASE WHEN player = 'Ryan' THEN
		percent_rank() OVER (PARTITION BY player ORDER BY coalesce(vote, 0))
	ELSE
		coalesce(vote / max(vote) OVER (PARTITION BY player), 0)
	END AS score,
	weight
FROM players_playing CROSS JOIN games LEFT JOIN player_votes USING (player, game)
--WHERE (owner IS NULL OR EXISTS (SELECT * FROM players_playing WHERE player = ANY (owner)))
;

CREATE VIEW game_scores AS
SELECT
	game, sum(score * weight) / sum(weight) AS real_score
FROM
	player_scores
GROUP BY
	game
;

CREATE VIEW final_scores AS
SELECT
	dense_rank() OVER (ORDER BY real_score DESC) AS rank, game, trim(to_char(real_score, '9D99999')) AS score
FROM
	game_scores
ORDER BY
	real_score DESC
;


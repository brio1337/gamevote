CREATE TABLE games (
	game text PRIMARY KEY,
	min_players integer,
	max_players integer,
	owner text[],
	base_time integer,
	time_per_player integer
);

CREATE TABLE players (
	player text PRIMARY KEY,
	playing boolean NOT NULL DEFAULT TRUE,
	weight double precision NOT NULL DEFAULT 1,
	hashed_password text,
	autosave boolean NOT NULL DEFAULT TRUE,
	num_tables integer NOT NULL DEFAULT 1
);

CREATE TABLE player_votes (
	player text REFERENCES players,
	game text REFERENCES games,
	vote double precision,
	PRIMARY KEY (player, game)
);

\ir views.sql

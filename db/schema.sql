CREATE TABLE games (
	game text PRIMARY KEY,
	min_players integer,
	max_players integer,
	base_time integer,
	time_per_player integer
);

CREATE TABLE players (
	player text PRIMARY KEY,
	playing boolean NOT NULL DEFAULT TRUE,
	weight double precision NOT NULL DEFAULT 1,
	hashed_password text,
	autosave boolean NOT NULL DEFAULT TRUE,
	birth_month integer,
	birth_day integer,
	allow_abstain boolean NOT NULL DEFAULT FALSE
);

CREATE TABLE player_votes (
	player text REFERENCES players,
	game text REFERENCES games,
	vote double precision,
	PRIMARY KEY (player, game)
);

CREATE TABLE game_owners (
	game text REFERENCES games,
	player text REFERENCES players,
	PRIMARY KEY (game, player)
);

\ir views.sql
\ir roles.sql
\ir api.sql
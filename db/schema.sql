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
	birth_day integer
);

CREATE TABLE player_votes (
	player text REFERENCES players,
	game text REFERENCES games,
	vote double precision,
	PRIMARY KEY (player, game)
);

CREATE TABLE libraries (
	library text PRIMARY KEY
);

CREATE TABLE game_owners (
	game text REFERENCES games NOT NULL,
	player text REFERENCES players,
	PRIMARY KEY (game, player)
);

CREATE TABLE library_games (
  library text REFERENCES libraries,
  game text REFERENCES games,
  PRIMARY KEY (library, game)
);

CREATE TABLE gaming_groups (
	gaming_group text PRIMARY KEY,
	library text REFERENCES libraries
);

CREATE TABLE group_players (
	gaming_group text REFERENCES gaming_groups,
	player text REFERENCES players,
	PRIMARY KEY (gaming_group, player)
);

\ir views.sql
\ir api.sql

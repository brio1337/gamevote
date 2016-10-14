DROP TABLE IF EXISTS past_plays CASCADE;
CREATE TABLE past_plays (
	id serial PRIMARY KEY,
	game text NOT NULL REFERENCES games,
	play_date date NOT NULL
);

DROP TABLE IF EXISTS past_players CASCADE;
CREATE TABLE past_players (
	play_id integer NOT NULL REFERENCES past_plays,
	player text NOT NULL REFERENCES players,
	PRIMARY KEY (play_id, player)
);



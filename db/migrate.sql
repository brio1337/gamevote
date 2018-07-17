DROP TABLE IF EXISTS game_owners;
CREATE TABLE game_owners (
	game text,
	player text,
	PRIMARY KEY (game, player)
);

INSERT INTO game_owners
SELECT game, unnest(owner) FROM games;

ALTER TABLE games DROP COLUMN owner CASCADE;

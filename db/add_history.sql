WITH ins AS (
	INSERT INTO plays (game, play_date) VALUES (:game)
INSERT INTO history (id, game, player)
SELECT nextval, :game, unnest(:players) FROM nextval('history_id_seq'::regclass);

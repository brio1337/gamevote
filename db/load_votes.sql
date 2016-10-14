CREATE FOREIGN TABLE pg_temp.player_file (
	game text,
	vote double precision,
	extra text
)
SERVER player_server
OPTIONS (filename :'player_file', format 'csv')
;

INSERT INTO player_votes (player, game, vote) SELECT initcap(:'player_name'), game, vote FROM pg_temp.player_file;

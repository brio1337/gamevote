
create or replace function pg_temp.assert(boolean) returns void as $$
begin
  IF NOT $1 THEN
    raise exception 'assert failure: not % is true', $1 using errcode = 'triggered_action_exception';
  END IF;
end
$$ language plpgsql set search_path from current immutable;

create or replace function pg_temp.assert_equal(ANYELEMENT, ANYELEMENT) returns void as $$
begin
  IF $1 IS DISTINCT FROM $2 THEN
    raise exception 'assert_equal failure: % is not equal %', $2, $1 using errcode = 'triggered_action_exception';
  END IF;
end
$$ language plpgsql set search_path from current immutable;

BEGIN;
DO $$
BEGIN
  PERFORM pg_temp.assert(in_birthday_window(make_date(2018, 1, 1), 1, 1));
  PERFORM pg_temp.assert(not in_birthday_window(make_date(2018, 1, 1), 2, 1));
  PERFORM pg_temp.assert(in_birthday_window(make_date(2018, 1, 1), 12, 29));
  PERFORM pg_temp.assert(not in_birthday_window(make_date(2018, 1, 1), 2, 29));
END
$$;
ROLLBACK;

BEGIN;
DO $$
DECLARE
  r record;
BEGIN
  INSERT INTO players VALUES ('Alice'), ('Bob'), ('Carol');
  INSERT INTO games VALUES
    ('g1', 2, 4),
    ('g2', 2, 4),
    ('g3', 2, 4);

  INSERT INTO game_owners VALUES
    ('g1', 'Alice'),
    ('g2', 'Alice'),
    ('g3', 'Alice');

  INSERT INTO player_votes VALUES
    ('Alice', 'g1', 10),
    ('Bob', 'g2', 3);

  SELECT rank, game, score INTO r FROM ranked_results WHERE rank = 1 LIMIT 1;

  PERFORM pg_temp.assert_equal('g1', r.game);
END
$$;
ROLLBACK;

BEGIN;
DO $$
DECLARE
  cursor REFCURSOR;
  record RECORD;
BEGIN
  INSERT INTO players VALUES
    ('Alice'),
    ('Bob'),
    ('Carol'),
    ('David'),
    ('Erika'),
    ('Frank');

  INSERT INTO games VALUES
    ('g1', 2, 4),
    ('g2', 2, 5),
    ('g3', 2, 6);

  INSERT INTO game_owners VALUES
    ('g1', 'Alice'),
    ('g2', 'Alice'),
    ('g3', 'Alice');

  INSERT INTO player_votes VALUES
    ('Alice', 'g1', 1),
    ('Bob', 'g1', 1),
    ('Bob', 'g2', 2),
    ('Carol', 'g2', 1),
    ('Carol', 'g3', 2),
    ('David', 'g3', 1),
    ('Erika', 'g1', 1),
    ('Frank', 'g2', 1);

  OPEN cursor FOR SELECT * FROM top_results_best_tables ORDER BY score DESC, game_1, game_2;
  FETCH cursor INTO record;
  PERFORM pg_temp.assert_equal('g1', record.game_1);
  PERFORM pg_temp.assert_equal('g2', record.game_2);
  FETCH cursor INTO record;
  PERFORM pg_temp.assert_equal('g1', record.game_1);
  PERFORM pg_temp.assert_equal('g3', record.game_2);
  FETCH cursor INTO record;
  PERFORM pg_temp.assert_equal('g3', record.game_1);
END
$$;
SELECT * FROM top_results_best_tables;
ROLLBACK;


-- Everyone would like to play 'awesome', but 2 people have to play 'terrible'.
BEGIN;
DO $$
DECLARE
  r record;
BEGIN
  INSERT INTO players VALUES
    ('Alice'),
    ('Bob'),
    ('Carol'),
    ('David');

  INSERT INTO games VALUES
    ('awesome', 2, 2),
    ('terrible', 2, 2);

  INSERT INTO game_owners VALUES
    ('awesome', 'Alice'),
    ('terrible', 'Alice');

  INSERT INTO player_votes VALUES
    ('Alice', 'awesome', 1),
    ('Bob', 'awesome', 1),
    ('Carol', 'awesome', 1),
    ('David', 'awesome', 1),
    ('Bob', 'terrible', 0.1),
    ('David', 'terrible', 0.1);

  SELECT * INTO r FROM top_results_best_tables;

  PERFORM pg_temp.assert_equal('{Alice,Carol}', r.player_group_1);
  PERFORM pg_temp.assert_equal('awesome', r.game_1);
  PERFORM pg_temp.assert_equal('{Bob,David}', r.player_group_2);
  PERFORM pg_temp.assert_equal('terrible', r.game_2);

  -- Now David buys a copy so everyone can play 'awesome'
  INSERT INTO game_owners VALUES
    ('awesome', 'David');

  SELECT * INTO r FROM top_results_best_tables ORDER BY player_group_1 LIMIT 1;

  PERFORM pg_temp.assert_equal('{Alice,Bob}', r.player_group_1);
  PERFORM pg_temp.assert_equal('awesome', r.game_1);
  PERFORM pg_temp.assert_equal('{Carol,David}', r.player_group_2);
  PERFORM pg_temp.assert_equal('awesome', r.game_2);

END
$$;
ROLLBACK;

-- Performance test with 6 players and 200 games
BEGIN;
DO $$
DECLARE
  start_time timestamptz;
  elapsed_time interval;
  num_players integer := 6;
  num_games integer := 200;
BEGIN
  INSERT INTO players SELECT * FROM generate_series(1, num_players);
  INSERT INTO games SELECT *, 2 + (random() * 2)::integer, 3 + (random() * 3)::integer FROM generate_series(1, num_games);
  INSERT INTO game_owners SELECT *, 1 FROM generate_series(1, num_games * 3 / 5);
  INSERT INTO game_owners SELECT *, 2 FROM generate_series(num_games * 2 / 5, num_games);
  INSERT INTO player_votes
  SELECT player, game, random() AS vote
  FROM
    generate_series(1, num_players) AS player,
    generate_series(1, num_games) AS game
  WHERE
    random() < 0.25;

  ANALYZE;

  start_time = clock_timestamp();
  PERFORM * FROM top_results_best_tables;
  elapsed_time = clock_timestamp() - start_time;
  IF elapsed_time > '5 seconds' THEN
    RAISE EXCEPTION 'Took % seconds to calculate with % players and % games', elapsed_time, num_players, num_games;
  END IF;
  RAISE NOTICE 'Took % seconds to calculate with % players and % games', elapsed_time, num_players, num_games;
END
$$;
ROLLBACK;

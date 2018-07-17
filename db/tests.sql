
create or replace function pg_temp.assert_equal(ANYELEMENT, ANYELEMENT) returns void as $$
begin
  IF $1 IS DISTINCT FROM $2 THEN
    raise exception 'assert_equal failure: % is not equal %', $2, $1 using errcode = 'triggered_action_exception';
  END IF;
end
$$ language plpgsql set search_path from current immutable;


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

  SELECT rank, game, score INTO r FROM final_scores LIMIT 1;

  PERFORM pg_temp.assert_equal(1::bigint, r.rank);
  PERFORM pg_temp.assert_equal('g1', r.game);
END
$$;
ROLLBACK;

BEGIN;
DO $$
DECLARE
  r record;
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

  SELECT game_1 INTO r FROM final_scores_two_tables;

  -- PERFORM pg_temp.assert_equal('g1', r.game_1);
END
$$;
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

  SELECT * INTO r FROM final_scores_two_tables;

  PERFORM pg_temp.assert_equal('{Alice,Carol}', r.player_group_1);
  PERFORM pg_temp.assert_equal('awesome', r.game_1);
  PERFORM pg_temp.assert_equal('{Bob,David}', r.player_group_2);
  PERFORM pg_temp.assert_equal('terrible', r.game_2);

  -- Now David buys a copy so everyone can play 'awesome'
  INSERT INTO game_owners VALUES
    ('awesome', 'David');

  SELECT * INTO r FROM final_scores_two_tables ORDER BY player_group_1 LIMIT 1;

  PERFORM pg_temp.assert_equal('{Alice,Bob}', r.player_group_1);
  PERFORM pg_temp.assert_equal('awesome', r.game_1);
  PERFORM pg_temp.assert_equal('{Carol,David}', r.player_group_2);
  PERFORM pg_temp.assert_equal('awesome', r.game_2);

END
$$;
ROLLBACK;

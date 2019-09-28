DROP VIEW IF EXISTS players_playing CASCADE;

CREATE OR REPLACE FUNCTION in_birthday_window(the_date date, birth_month integer, birth_day integer)
RETURNS BOOLEAN AS $$
DECLARE
	the_year integer := extract(year from the_date)::integer;
	the_month integer := extract(month from the_date)::integer;
	test_year integer;
	nearest_birth_date date;
BEGIN
	test_year := the_year + CASE
		WHEN the_month >= 12 AND birth_month <= 1 THEN 1
		WHEN the_month <= 1 AND birth_month >= 12 THEN -1
		ELSE 0
	END;
	BEGIN
		nearest_birth_date := make_date(test_year, birth_month, birth_day);
	EXCEPTION WHEN OTHERS THEN
		nearest_birth_date := make_date(test_year, birth_month + 1, 1);
	END;
	RETURN abs(nearest_birth_date - the_date) <= 4;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE VIEW players_playing AS
SELECT
	player,
	CASE
		WHEN in_birthday_window(current_date, birth_month, birth_day) THEN weight * 2
		ELSE weight
	END AS weight,
	allow_abstain
FROM players
WHERE playing;

CREATE OR REPLACE VIEW player_groups AS
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
WHERE array_upper(player_list, 1) BETWEEN 2 AND (SELECT count(*) FROM players_playing) - 2
;

CREATE OR REPLACE VIEW games_available AS
SELECT
	game, player AS owner
FROM
	game_owners JOIN players_playing USING (player)
;

CREATE OR REPLACE VIEW player_scores AS
SELECT
	player, game, owner,
	coalesce(vote / nullif(max(vote) OVER (PARTITION BY player), 0), 0) AS score,
	CASE WHEN vote IS NULL AND allow_abstain THEN NULL ELSE weight END AS weight
FROM
	players_playing
	CROSS JOIN games_available
	LEFT JOIN player_votes USING (player, game)
;

CREATE OR REPLACE VIEW game_scores AS
SELECT
	game, coalesce(sum(score * weight) / sum(weight), 0) AS score
FROM
	player_scores JOIN games USING (game)
WHERE
	coalesce((SELECT count(*) FROM players_playing) >= min_players, TRUE) AND
	coalesce((SELECT count(*) FROM players_playing) <= max_players, TRUE)
GROUP BY
	game
;

CREATE OR REPLACE VIEW ranked_results AS
SELECT
	dense_rank() OVER (ORDER BY score DESC) AS rank,
	game,
	score
FROM
	game_scores
;

CREATE OR REPLACE VIEW player_group_game_scores AS
SELECT
	game, owner,
	player_group_1,
		sum(score * weight) FILTER (WHERE player = ANY(player_group_1)) AS score_1,
		sum(weight) FILTER (WHERE player = ANY(player_group_1)) AS weight_1,
	player_group_2,
		sum(score * weight) FILTER (WHERE player = ANY(player_group_2)) AS score_2,
		sum(weight) FILTER (WHERE player = ANY(player_group_2)) AS weight_2,
		coalesce(array_upper(player_group_1, 1) >= min_players, TRUE) AND
		coalesce(array_upper(player_group_1, 1) <= max_players, TRUE) AS would_play_1,
		coalesce(array_upper(player_group_2, 1) >= min_players, TRUE) AND
		coalesce(array_upper(player_group_2, 1) <= max_players, TRUE) AS would_play_2
FROM
	player_groups, games_available
	JOIN games USING (game)
	JOIN player_scores USING (game, owner)
GROUP BY
	game, owner, player_group_1, player_group_2, would_play_1, would_play_2
;

CREATE OR REPLACE VIEW results_two_tables AS
WITH player_group_game_scores AS (SELECT * FROM player_group_game_scores)
SELECT
	player_group_1, t1.game AS game_1,
	player_group_2, t2.game AS game_2,
	coalesce((t1.score_1 + t2.score_2) / (t1.weight_1 + t2.weight_2), 0) AS score,
	abs(array_upper(player_group_1, 1) - array_upper(player_group_2, 1)) + 1 AS balance
FROM
	player_group_game_scores t1 JOIN
	player_group_game_scores t2 USING (player_group_1, player_group_2)
WHERE
	t1.would_play_1 AND t2.would_play_2 AND
	NOT (t1.game = t2.game AND t1.owner = t2.owner)
;

CREATE OR REPLACE VIEW ranked_results_two_tables AS
WITH
	results_two_tables AS (SELECT * FROM results_two_tables),
	top_each_balance AS (SELECT balance, max(score) AS score FROM results_two_tables GROUP BY balance)
SELECT
	player_group_1, game_1,
	player_group_2, game_2,
	score, balance
FROM
	results_two_tables JOIN top_each_balance USING (score, balance)
;

CREATE OR REPLACE VIEW top_results_all_tables AS
SELECT
	(SELECT array_agg(player ORDER BY player) FROM players_playing) AS player_group_1,
	game AS game_1,
	NULL AS player_group_2,
	NULL AS game_2,
	score, 0 AS balance
FROM
	ranked_results
WHERE
	rank = 1
UNION
SELECT
	player_group_1, game_1,
	player_group_2, game_2,
	score, balance
FROM
	ranked_results_two_tables
;

CREATE OR REPLACE VIEW top_results_best_tables AS
WITH top_results_with_best_balance AS (
	SELECT
		player_group_1, game_1, player_group_2, game_2, score, balance,
		first_value(balance) OVER (ORDER BY score DESC, balance) AS best_balance
	FROM
		top_results_all_tables
)
SELECT player_group_1, game_1, player_group_2, game_2, score
FROM top_results_with_best_balance
WHERE balance <= best_balance
;

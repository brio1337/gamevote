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
	gaming_group,
	player,
	CASE
		WHEN in_birthday_window(current_date, birth_month, birth_day) THEN weight * 2
		ELSE weight
	END AS weight
FROM group_players JOIN players USING (player)
WHERE playing
;

CREATE OR REPLACE VIEW player_groups AS
WITH RECURSIVE subgroups (gaming_group, num_in_group, first_in_group, player_list) AS (
	SELECT
		gaming_group,
		count(*) OVER (PARTITION BY gaming_group) AS num_in_group,
		min(player) OVER (PARTITION BY gaming_group) AS first_in_group,
		ARRAY[player] AS player_list
	FROM players_playing
	UNION ALL
	SELECT gaming_group, num_in_group, first_in_group, player_list || player
	FROM subgroups JOIN players_playing USING (gaming_group)
	WHERE player_list[array_upper(player_list, 1)] < player
		AND ((array_upper(player_list, 1) + 1) * 2 < num_in_group OR (
			(array_upper(player_list, 1) + 1) * 2 = num_in_group
			AND player_list[1] = first_in_group)
		)
)
SELECT
	gaming_group,
	player_list AS player_group_1,
	array_agg(player ORDER BY player) AS player_group_2
FROM subgroups JOIN players_playing USING (gaming_group)
WHERE array_upper(player_list, 1) >= 2 AND player != ALL(player_list)
GROUP BY gaming_group, player_list
HAVING count(*) >= 2
;

CREATE OR REPLACE VIEW games_available AS
SELECT gaming_group, game, player AS owner
FROM gaming_groups JOIN players_playing USING (gaming_group) JOIN game_owners USING (player)
WHERE gaming_groups.library IS NULL
UNION
SELECT gaming_group, game, NULL
FROM gaming_groups JOIN library_games USING (library)
;

CREATE OR REPLACE VIEW player_scores AS
SELECT
	gaming_group, player, weight, game, owner,
	coalesce(vote / nullif(max(vote) OVER (PARTITION BY gaming_group, player), 0), 0) AS score
FROM
	players_playing
	JOIN games_available USING (gaming_group)
	LEFT JOIN player_votes USING (player, game)
;

CREATE OR REPLACE VIEW game_scores AS
SELECT
	gaming_group,
	array_agg(player ORDER BY player) AS player_group,
	game,
	coalesce(sum(score * weight) / sum(weight), 0) AS score
FROM
	player_scores JOIN games USING (game)
GROUP BY
	gaming_group, game, min_players, max_players
HAVING
	coalesce(count(*) BETWEEN min_players AND max_players, TRUE)
;

CREATE OR REPLACE VIEW ranked_results AS
SELECT
	gaming_group, player_group, game, score,
	dense_rank() OVER (PARTITION BY gaming_group ORDER BY score DESC) AS rank
FROM
	game_scores
;

CREATE OR REPLACE VIEW player_group_game_scores AS
SELECT
	gaming_group, game, owner,
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
	player_groups JOIN games_available USING (gaming_group)
	JOIN games USING (game)
	JOIN player_scores USING (gaming_group, game, owner)
GROUP BY
	gaming_group, game, owner, player_group_1, player_group_2, would_play_1, would_play_2
;

CREATE OR REPLACE VIEW results_two_tables AS
WITH player_group_game_scores AS (SELECT * FROM player_group_game_scores)
SELECT
	gaming_group,
	player_group_1, t1.game AS game_1,
	player_group_2, t2.game AS game_2,
	coalesce((t1.score_1 + t2.score_2) / (t1.weight_1 + t2.weight_2), 0) AS score,
	abs(array_upper(player_group_1, 1) - array_upper(player_group_2, 1)) + 1 AS balance
FROM
	player_group_game_scores t1 JOIN
	player_group_game_scores t2 USING (gaming_group, player_group_1, player_group_2)
WHERE
	t1.would_play_1 AND t2.would_play_2 AND
	NOT coalesce(t1.game = t2.game AND t1.owner = t2.owner, FALSE)
;

CREATE OR REPLACE VIEW top_results_two_tables AS
WITH
	results_two_tables AS (SELECT * FROM results_two_tables),
	top_each_balance AS (
		SELECT gaming_group, balance, max(score) AS score
		FROM results_two_tables
		GROUP BY gaming_group, balance
	)
SELECT
	gaming_group,
	balance,
	player_group_1, game_1,
	player_group_2, game_2,
	score
FROM
	results_two_tables JOIN top_each_balance USING (gaming_group, balance, score)
;

CREATE OR REPLACE VIEW top_results_all_tables AS
SELECT * FROM top_results_two_tables
UNION
SELECT
	gaming_group,
	0 AS balance,
	player_group AS player_group_1,
	game AS game_1,
	NULL AS player_group_2,
	NULL AS game_2,
	score
FROM
	ranked_results
WHERE
	rank = 1
;

CREATE OR REPLACE VIEW top_results_best_tables AS
WITH top_results_with_best_balance AS (
	SELECT
		gaming_group, player_group_1, game_1, player_group_2, game_2, score, balance,
		first_value(balance) OVER (PARTITION BY gaming_group ORDER BY score DESC, balance) AS best_balance
	FROM
		top_results_all_tables
)
SELECT gaming_group, player_group_1, game_1, player_group_2, game_2, score
FROM top_results_with_best_balance
WHERE balance <= best_balance
;

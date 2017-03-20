CREATE OR REPLACE VIEW players_playing AS
SELECT * FROM players WHERE playing;

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
WHERE array_upper(player_list, 1) >= 2 AND
array_upper(player_list, 1) * 2 - (SELECT count(*) FROM players_playing) BETWEEN -1 AND 1
;

CREATE OR REPLACE VIEW player_scores AS
SELECT
	player,
	game,
	CASE WHEN player = 'Ryan' THEN
		percent_rank() OVER (PARTITION BY player ORDER BY coalesce(vote, 0))
	ELSE
		coalesce(vote / nullif(max(vote) OVER (PARTITION BY player), 0), 0)
	END AS score,
	weight
FROM players_playing CROSS JOIN games LEFT JOIN player_votes USING (player, game)
WHERE (owner IS NULL OR EXISTS (SELECT * FROM players_playing WHERE player = ANY (owner)))
;

CREATE OR REPLACE VIEW game_scores AS
SELECT
	game, sum(score * weight) / sum(weight) AS real_score
FROM
	player_scores JOIN games USING (game)
WHERE
	coalesce((SELECT count(*) FROM players_playing) >= min_players, TRUE) AND
	coalesce((SELECT count(*) FROM players_playing) <= max_players, TRUE)
GROUP BY
	game
;

CREATE OR REPLACE VIEW final_scores AS
SELECT
	dense_rank() OVER (ORDER BY real_score DESC) AS rank, game, trim(to_char(real_score, '9D99999')) AS score
FROM
	game_scores
ORDER BY
	real_score DESC
;

CREATE OR REPLACE VIEW final_scores_two_tables AS
WITH
player_group_game_scores AS (
SELECT game, min_players, max_players, base_time, time_per_player,
	player_group_1,
		sum(score * weight) FILTER (WHERE player = ANY(player_group_1)) AS score_1,
		sum(weight) FILTER (WHERE player = ANY(player_group_1)) AS weight_1,
	player_group_2,
		sum(score * weight) FILTER (WHERE player = ANY(player_group_2)) AS score_2,
		sum(weight) FILTER (WHERE player = ANY(player_group_2)) AS weight_2
FROM player_groups CROSS JOIN games INNER JOIN player_scores USING (game)
WHERE owner IS NULL OR EXISTS (SELECT * FROM players_playing WHERE player = ANY(owner))
GROUP BY game, min_players, max_players, base_time, time_per_player, player_group_1, player_group_2
),
results AS (
SELECT
	player_group_1, t1.game AS game_1,
	player_group_2, t2.game AS game_2,
	(t1.score_1 + t2.score_2) / (t1.weight_1 + t2.weight_2) AS real_score
FROM
	player_group_game_scores t1 JOIN player_group_game_scores t2 USING (player_group_1, player_group_2)
WHERE
	coalesce(array_upper(player_group_1, 1) >= t1.min_players, TRUE) AND
	coalesce(array_upper(player_group_1, 1) <= t1.max_players, TRUE) AND
	coalesce(array_upper(player_group_2, 1) >= t2.min_players, TRUE) AND
	coalesce(array_upper(player_group_2, 1) <= t2.max_players, TRUE)
)
SELECT
	dense_rank() OVER (ORDER BY real_score DESC NULLS LAST) AS rank,
	player_group_1, game_1,
	player_group_2, game_2,
	trim(to_char(real_score, '9D99999')) AS score
FROM
	results
ORDER BY
	real_score DESC NULLS LAST

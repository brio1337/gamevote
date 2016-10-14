WITH
player_group_game_scores AS (
SELECT game, min_players, max_players, base_time, time_per_player,
	player_group_1,
		sum(score * weight) FILTER (WHERE player = ANY(player_group_1)) AS score_1,
		sum(weight) FILTER (WHERE player = ANY(player_group_1)) AS weight_1,
	player_group_2,
		sum(score * weight) FILTER (WHERE player = ANY(player_group_2)) AS score_2,
		sum(weight) FILTER (WHERE player = ANY(player_group_2)) AS weight_2
FROM player_groups CROSS JOIN games INNER JOIN weighted_scores USING (game)
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
	@(array_upper(player_group_1, 1) - array_upper(player_group_2, 1)) <= 1 AND
--	(
--		(t1.base_time + t1.time_per_player * array_upper(player_group_1, 1) <= 90 AND 'Karen'=ANY(player_group_1)) OR
--		(t2.base_time + t2.time_per_player * array_upper(player_group_2, 1) <= 90 AND 'Karen'=ANY(player_group_2))
--	) AND
	coalesce(array_upper(player_group_1, 1) >= t1.min_players, TRUE) AND
	coalesce(array_upper(player_group_1, 1) <= t1.max_players, TRUE) AND
	coalesce(array_upper(player_group_2, 1) >= t2.min_players, TRUE) AND
	coalesce(array_upper(player_group_2, 1) <= t2.max_players, TRUE)
)
SELECT
	dense_rank() OVER (ORDER BY real_score DESC NULLS LAST) AS rank,
	player_group_1, left(game_1, 30) AS game_1,
	player_group_2, left(game_2, 30) AS game_2,
	trim(to_char(real_score, '9D99999')) AS score
FROM
	results
--WHERE
--	('Roland'=ANY(player_group_1) AND 'Karen'=ANY(player_group_1)) OR
--	('Roland'=ANY(player_group_2) AND 'Karen'=ANY(player_group_2))
ORDER BY
	real_score DESC NULLS LAST
--LIMIT 25

WITH results AS (
SELECT
	game, weighted_avg(ws.score, ws.weight) AS real_score
FROM
	players_playing CROSS JOIN games INNER JOIN weighted_scores ws USING (player, game)
WHERE
	--coalesce(base_time,0) + coalesce(time_per_player * (SELECT count(*) FROM players_playing),0) <= 60 AND
	coalesce((SELECT count(*) FROM players_playing) >= min_players, TRUE) AND
	coalesce((SELECT count(*) FROM players_playing) <= max_players, TRUE) AND
	--(owner IS NULL OR EXISTS (SELECT * FROM players_playing WHERE player = ANY (owner)))
	TRUE
GROUP BY
	game
)
SELECT
	dense_rank() OVER (ORDER BY real_score DESC) AS rank, game, trim(to_char(real_score, '9D99999')) AS score
FROM
	results
ORDER BY
	real_score DESC
;


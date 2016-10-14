CREATE OR REPLACE VIEW scores (player, game, score) AS
SELECT 'Bill', game, coalesce(num / max(num) OVER (), 0)
FROM games LEFT JOIN bill USING (game)
UNION ALL
SELECT 'Brian', game, coalesce(num / max(num) OVER (), 0)
FROM games LEFT JOIN brian USING (game)
UNION ALL
SELECT 'Consty', game, coalesce(num / max(num) OVER (), 0)
FROM games LEFT JOIN consty USING (game)
UNION ALL
SELECT 'Roland', game, coalesce(num / max(num) OVER (), 0)
FROM games LEFT JOIN roland USING (game)
UNION ALL
SELECT 'Ryan', game, percent_rank() OVER (ORDER BY coalesce(num, 0))
FROM games LEFT JOIN ryan USING (game) WHERE num IS NOT NULL
UNION ALL
SELECT 'Sean', game, coalesce(num / max(num) OVER (), 0)
FROM games LEFT JOIN sean USING (game)
UNION ALL
SELECT 'Tony', game, coalesce(num / max(num) OVER (), 0)
FROM games LEFT JOIN tony USING (game)
UNION ALL
SELECT 'Tristan', game, coalesce(num / max(num) OVER (), 0)
FROM games LEFT JOIN tristan USING (game)
UNION ALL
SELECT 'Karen', game, coalesce(num / max(num) OVER (), 0)
FROM games LEFT JOIN karen USING (game)
;

CREATE OR REPLACE VIEW weighted_scores (player, game, score, weight) AS
SELECT player, game, score / max(score) OVER (PARTITION BY player), weight
FROM players_playing CROSS JOIN games LEFT JOIN scores USING (player, game)
--WHERE (owner IS NULL OR EXISTS (SELECT * FROM players_playing WHERE player = ANY (owner)))
;

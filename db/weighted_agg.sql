CREATE OR REPLACE FUNCTION weighted_avg_state(float8[], float8, float8)
RETURNS float8[]
LANGUAGE sql IMMUTABLE STRICT AS $$
SELECT array [ $1[1] + $2 * $3, $1[2] + $3 ];
$$;

CREATE OR REPLACE FUNCTION weighted_avg_final(float8[])
RETURNS float8
LANGUAGE sql IMMUTABLE STRICT AS $$
SELECT $1[1] / $1[2];
$$;

CREATE AGGREGATE weighted_avg(float8, float8) (
	sfunc = weighted_avg_state,
	stype = float8[],
	finalfunc = weighted_avg_final,
	initcond = '{0,0}'
);



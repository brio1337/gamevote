set -e

export PGHOST=gamevote.cvsbgivadrlp.us-west-2.rds.amazonaws.com 
export PGUSER=games

psql <<SQL
	DROP SCHEMA IF EXISTS public CASCADE;
	CREATE SCHEMA public;
SQL

[ ! -f games.dump ] || psql -v ON_ERROR_STOP=1 -f games.dump

set -e

export PGHOST=gamevote.cvsbgivadrlp.us-west-2.rds.amazonaws.com 
export PGUSER=games

psql <<SQL
	DROP SCHEMA IF EXISTS public CASCADE;
	CREATE SCHEMA public;
SQL

psql -v ON_ERROR_STOP=1 -f schema.sql
[ ! -f games.dump ] || psql -v ON_ERROR_STOP=1 -f games.dump

set -e

source env/local

PSQL="psql -v ON_ERROR_STOP=1"

dropdb --if-exists games
createdb games
$PSQL -f games.dump
#pg_restore -d games games.dump
migration_list=(migrations/*)
$PSQL ${migration_list[@]/#/-f }

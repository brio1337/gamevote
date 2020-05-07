set -e

source env/local

PSQL="psql -v ON_ERROR_STOP=1"

# dropdb --if-exists games
createdb games 2>/dev/null || true
$PSQL -c "DROP SCHEMA public CASCADE"
$PSQL -c "CREATE SCHEMA public"
[ -e games.dump ] || ./dump.sh
$PSQL -f games.dump
migration_list=(migrations/*)
$PSQL ${migration_list[@]/#/-f }

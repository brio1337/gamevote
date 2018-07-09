set -e

PSQL="psql -v ON_ERROR_STOP=1"

dropdb --if-exists games_test
createdb games_test
$PSQL -U games -d games_test -f schema.sql
$PSQL -U games -d games_test -f tests.sql

echo "Success"

set -e

os_name=$(uname)

export PGPASSWORD=games

if [[ $os_name = Linux ]]; then
	which psql > /dev/null || sudo apt-get install postgresql
	if psql -U games -d postgres -c "SELECT 1" > /dev/null 2>&1; then
		sudo sed -i -r -e 's/(local\s+all\s+all\s+)peer/\1md5/' /etc/postgresql/9.5/main/pg_hba.conf
		sudo pg_ctlcluster 9.5 main reload
	fi
elif [[ $os_name = Darwin ]]; then
	which psql > /dev/null || brew install postgresql
	export PGDATA=pgdata
	! pg_ctl status || pg_ctl stop
	rm -rf pgdata
	if mkdir pgdata; then
		initdb
		pg_ctl start
		createuser games
	fi
	pg_ctl status || pg_ctl start
fi

dropdb --if-exists games
createdb games -O games

PSQL="psql -v ON_ERROR_STOP=1"

$PSQL games <<< "ALTER SYSTEM SET work_mem = '64MB';"
pg_ctl reload

if [ -f games.dump ]; then
	$PSQL -U games -f games.dump
else
	$PSQL -U games -f schema.sql
fi

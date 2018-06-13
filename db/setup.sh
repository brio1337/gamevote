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
	mkdir pgdata
	PGDATA=pgdata
	initdb
	pg_ctl start
fi

createuser games
createdb games -O games

psql -U games -v ON_ERROR_STOP=1 -f schema.sql

[ ! -f games.dump ] || psql -U games -v ON_ERROR_STOP=1 -f games.dump

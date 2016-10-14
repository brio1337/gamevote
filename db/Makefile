players = brian ryan sean roland tony karen

all: setup load

setup:
	which psql > /dev/null || sudo apt-get install postgresql
	psql -U games -d postgres -c "SELECT 1" > /dev/null 2>&1 || sudo sed -i -r -e 's/(local\s+all\s+all\s+)peer/\1md5/' /etc/postgresql/9.5/main/pg_hba.conf
	psql -U games -c "SELECT 1" > /dev/null 2>&1 || sudo -u postgres psql -v ON_ERROR_STOP=1 -f setupdb.sql
	psql -U games -v ON_ERROR_STOP=1 -f schema.sql

load: $(players)

$(players): setup
	sudo -u postgres psql games -v ON_ERROR_STOP=1 -v player_file=`realpath $@.txt` -v player_name=$@ -f load_votes.sql

.PHONY: $(players) setup load

set -e

which psql > /dev/null || sudo apt-get install postgresql
if PGPASSWORD=games psql -U games -d postgres -c "SELECT 1" > /dev/null 2>&1; then
	sudo sed -i -r -e 's/(local\s+all\s+all\s+)peer/\1md5/' /etc/postgresql/9.5/main/pg_hba.conf
	sudo pg_ctlcluster 9.5 main reload
fi
PGPASSWORD=games psql -U games -c "SELECT 1" > /dev/null 2>&1 || sudo -u postgres psql -v ON_ERROR_STOP=1 -f setupdb.sql
PGPASSWORD=games psql -U games -v ON_ERROR_STOP=1 -f schema.sql

for player in brian ryan sean roland tony karen; do
	sudo -u postgres psql games -v ON_ERROR_STOP=1 -v player_file=`realpath $player.txt` -v player_name=$player -f load_votes.sql
done

set -e
git push --force ssh://ubuntu@brio.software:/home/ubuntu/gamevote master
ssh ubuntu@brio.software <<EOF
set -e
cd gamevote
git reset --hard
sudo systemctl restart node
psql -v ON_ERROR_STOP=1 -U games -f db/views.sql
EOF

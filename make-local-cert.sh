set -e
domain=localhost
key_path="/etc/letsencrypt/live/$domain"
mkdir -p "./data/certbot/conf/live/$domain"
docker-compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:1024 -days 1\
    -keyout '$key_path/privkey.pem' \
    -out '$key_path/fullchain.pem' \
    -subj '/CN=localhost'" certbot

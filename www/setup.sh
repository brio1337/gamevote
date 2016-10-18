sudo apt install npm nodejs-legacy
sudo setcap 'cap_net_bind_service=+ep' $(readlink -f $(which node))
rm -rf node_modules
npm install

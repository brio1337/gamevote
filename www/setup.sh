set -e

os_name=$(uname)

if [[ $os_name = Linux ]]; then
    sudo apt install npm nodejs-legacy
    sudo setcap 'cap_net_bind_service=+ep' $(readlink -f $(which node))
elif [[ $os_name = Darwin ]]; then
    brew install node
fi
rm -rf node_modules
npm install
openssl req -x509 -newkey rsa:2048 -nodes \
    -subj "/C=CA/ST=BC/L=Victoria/O=brio o/OU=brio ou/CN=brio.software" \
    -out cert.pem -keyout key.pem

var express = require('express');
var fs = require('fs');
var https = require('https');
const app = require('./app');

app.listen(80);

https.createServer({
	key: fs.readFileSync('key.pem'),
	cert: fs.readFileSync('cert.pem'),
}, app).listen(443);

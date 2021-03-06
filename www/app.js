var fs = require('fs');
var express = require('express');
var session = require('express-session');
var bodyParser = require('body-parser');
var app = express();

// config
var connstr = process.env.DB_CONN_STR;
var saltRounds = 10;

// load middleware
app.set('view engine', 'hbs');
app.use(express.static('static'));
app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());
app.use(session({
	resave: false,
	saveUninitialized: false,
	secret: 'not very secret',
}));

// load the modules, pass in configs
var routeData = {
	login: [connstr],
	logout: [],
	password: [connstr, saltRounds],
	games: [connstr],
	autosave: [connstr],
	configure: [connstr],
	winner: [connstr],
};

for (mod in routeData) {
	require('./' + mod + '/' + mod).apply(null, [app, '/' + mod].concat(routeData[mod]));
}

app.get('/', function(req, res) {
	res.redirect(req.session.user ? '/games' : '/login');
});

module.exports = app;

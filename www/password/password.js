var pg = require('pg');
var bcrypt = require('bcrypt');
var modulename = require('../util').filenameToModulename(__filename);

module.exports = function(app, route, connstr, saltRounds) {
  app.get(route, get);
  app.post(route, post);

  function get(req, res) {
  	var user = req.session.user;
  	if (!user) {
  		return res.redirect('/login');
  	}
  	return res.render(modulename, {username: user});
  }

  function post(req, res) {
  	var user = req.session.user;
  	if (!user) {
  		return res.redirect('/login');
  	}
  	var password = req.body.password || '';
  	bcrypt.hash(password, saltRounds, function(err, hash) {
  		if (err) {
  			return res.status(500).type('text/plain').send(err.toString());
  		}
  		pg.connect(connstr, function(err, client, done) {
  			if (err) {
  				done();
  				return res.status(500).type('text/plain').send(err.toString());
  			}
  			var sql = 'UPDATE players SET hashed_password = $1 WHERE player = $2';
  			client.query({text: sql, values: [hash, user]}, function(err, result) {
  				done();
  				if (err) {
  					return res.status(500).type('text/plain').send(err.toString());
  				}
  				return res.redirect('/games');
  			});
  		});
  	});
  }
};

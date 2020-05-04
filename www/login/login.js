var pg = require('pg');
var bcrypt = require('bcrypt-nodejs');
var modulename = require('../util').filenameToModulename(__filename);

module.exports = function(app, route, connstr) {
  app.get(route, get);
  app.post(route, post);

  function get(req, res) {
    // Consider this page to be an error page, like a 404 page, but 401 instead.
    return res.status(401).render(modulename);
  }

  function post(req, res) {
    // the post function eventually calls resultForPasswordCheck
    function resultForPasswordCheck(check) {
      if (check) {
        req.session.user = username;
        return res.redirect('/games');
      } else {
        return res.status(400).render(modulename, {errorMsg: 'Wrong password'});
      }
    }

  	// check params
  	var username = req.body.username;
  	var password = req.body.password || '';
  	if (!username) {
  		return res.status(400).render(modulename, {errorMsg: 'Need a Name'});
  	}
  	pg.connect(connstr, function(err, client, done) {
  		if (err) {
  			done();
  			return res.status(500).render(modulename, {errorMsg: `error connecting to database: ${err.message}`});
  		}
  		var sql = 'SELECT hashed_password FROM players WHERE player = $1';
  		client.query({text: sql, values: [username]}, function(err, result) {
  			done();
  			if (err) {
  				return res.status(500).render(modulename, {errorMsg: err.toString()});
  			}
  			if (result.rows.length === 0) {
  				return res.status(404).render(modulename, {errorMsg: 'Name not found'});
  			}
  			var dbHashedPassword = result.rows[0].hashed_password;
  			if (!dbHashedPassword) {
          return resultForPasswordCheck(!password);
        }
  			bcrypt.compare(password, dbHashedPassword, function(err, equal) {
  				if (err) {
  					return res.status(500).render(modulename, {errorMsg: err.toString()});
  				}
          return resultForPasswordCheck(equal);
  			});
  		});
  	});
  }
};

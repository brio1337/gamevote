var pg = require('pg');
var modulename = require('../util').filenameToModulename(__filename);

module.exports = function(app, route, connstr, saltRounds) {
  app.get(route, get);
  app.post(route, post);

  function get(req, res) {
  	var user = req.session.user;
  	if (!user) {
  		return res.redirect('/login');
  	}
  	pg.connect(connstr, function(err, client, done) {
  		if (err) {
  			done();
  			return res.status(500).type('text/plain').send(err.toString());
  		}
      return buildResult(user, client, done, res);
  	});
  }

  function post(req, res) {
  	var user = req.session.user;
  	if (!user) {
  		return res.redirect('/login');
  	}
  	pg.connect(connstr, function(err, client, done) {
  		if (err) {
  			done();
  			return res.status(500).type('text/plain').send(err.toString());
  		}
  		var values = [user];
      var sql = 'DELETE FROM player_votes WHERE player = $1';
      var keys = Object.keys(req.body);
      console.log('inserting ' + keys.length + ' votes');
      if (keys.length > 0) {
		    sql = 'WITH del AS (' + sql + ') ';
		    sql += 'INSERT INTO player_votes (player, game, vote) VALUES ';
		    var paramNum = 2;
    		for (var i = 0; i < keys.length; i++) {
    			if (i > 0) sql += ',';
    			sql += '($' + (i*3+2) + ',$' + (i*3+3) + ',$' + (i*3+4) + ')';
    			values.push(user, keys[i], req.body[keys[i]]);
        }
        sql += ' ON CONFLICT (player, game) DO UPDATE SET vote = excluded.vote';
  		}
  		client.query({text: sql, values: values}, function(err, result) {
  			if (err) {
          done();
  				return res.status(500).type('text/plain').send(err.toString());
  			}
        return buildResult(user, client, done, res);
  		});
    });
  }
  
  function buildResult(user, client, done, res) {
    var sql =
      'SELECT games.game, vote ' +
      'FROM games LEFT JOIN player_votes ' +
      'ON games.game = player_votes.game AND player = $1 ' +
      'ORDER BY vote DESC, game';
    client.query({text: sql, values: [user]}, function(err, result) {
      done();
      if (err) {
        return res.status(500).type('text/plain').send(err.toString());
      }
      return res.render(modulename, {
        username: user,
        gamelist: result.rows.filter(row => row.vote !== null),
        unranked: result.rows.filter(row => row.vote === null),
      });
    });
  }
};

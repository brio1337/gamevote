var pg = require('pg');
var modulename = require('../util').filenameToModulename(__filename);

module.exports = function(app, route, connstr) {
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
			var sql = `SELECT player, playing, weight*100 AS weight, num_tables
				FROM players ORDER BY player`;
			client.query({text: sql}, function(err, result) {
				done();
				if (err) {
					return res.status(500).type('text/plain').send(err.toString());
				}
				var userRow = result.rows.find(element => element.player === user);
				if (!userRow) {
					return res.status(500).type('text/plain').send('No current user');
				}
				var numTables = userRow.num_tables;
				return res.render(modulename, {
					players: result.rows,
					one_table: numTables === 1,
					two_tables: numTables === 2,
				});
			});
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
			var sql = 'UPDATE players SET playing = (player IN (';
			var values = [];
			var pos = 1;
			for (var a in req.body) {
				if (a === 'tables') continue;
				if (pos > 1) sql += ',';
				sql += '$' + pos++;
				values.push(a);
			}
			sql += ')), num_tables = CASE player WHEN $' + pos++ + ' THEN $' + pos++ + ' ELSE num_tables END';
			values.push(user, req.body.tables);
			client.query({text: sql, values: values}, function(err, result) {
				done();
				if (err) {
					return res.status(500).type('text/plain').send(err.toString());
				}
				return res.redirect('/games');
			});
		});
	}
};

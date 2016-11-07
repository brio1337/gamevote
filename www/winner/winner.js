var pg = require('pg');

module.exports = function(app, route, connstr) {
  app.get(route, get);

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
      var sql = 'SELECT num_tables FROM players WHERE player = $1';
      client.query({text: sql, values: [user]}, function(err, result) {
        if (err) {
          done();
          return res.status(500).type('text/plain').send(err.toString());
        }
        if (result.rows.length === 0) {
          done();
          return res.status(400).type('text/plain').send('User not found');
        }
        var numTables = result.rows[0].num_tables;
        var numTableInfo = {
          1: {
            sql: 'SELECT game FROM final_scores WHERE rank = 1',
            toString: row => row.game,
          },
          2: {
            sql: 'SELECT player_group_1, game_1, player_group_2, game_2 FROM final_scores_two_tables WHERE rank = 1',
            toString: function(row) {
              return row.player_group_1.join(', ') + ': ' + row.game_1 + ' / ' + row.player_group_2.join(', ') + ': ' + row.game_2;
            },
          },
        }
        client.query({text: numTableInfo[numTables].sql}, function(err, result) {
          done();
          if (err) {
            return res.status(500).type('text/plain').send(err.toString());
          }
          var rows = result.rows;
          return res.send(rows.map(numTableInfo[numTables].toString).join('\n'));
        });
      });
    });
  }
};

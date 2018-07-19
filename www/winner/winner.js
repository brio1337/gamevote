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
      client.query({text: 'SELECT player_group_1, game_1, player_group_2, game_2 FROM top_results_best_tables'}, function(err, result) {
        done();
        if (err) {
          return res.status(500).type('text/plain').send(err.toString());
        }
        return res.send(result.rows.map(function(row) {
          if (!row.game_2) {
            return row.player_group_1.join(', ') + ': ' + row.game_1;
          } else {
            if (row.game_1 < row.game_2) {
              var player_group_1 = row.player_group_1;
              var game_1 = row.game_1;
              var player_group_2 = row.player_group_2;
              var game_2 = row.game_2;
            } else {
              var player_group_1 = row.player_group_2;
              var game_1 = row.game_2;
              var player_group_2 = row.player_group_1;
              var game_2 = row.game_1;
            }
            return player_group_1.join(', ') + ': ' + game_1 + ' / ' + player_group_2.join(', ') + ': ' + game_2;
          }
        }).join('\n'));
      });
    });
  }
};

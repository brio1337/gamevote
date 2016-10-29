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
      var sql = 'SELECT game FROM final_scores LIMIT 1';
      client.query({text: sql}, function(err, result) {
        done();
        if (err) {
          return res.status(500).type('text/plain').send(err.toString());
        }
        return res.send(result.rows[0].game);
      });
    });
  }
};

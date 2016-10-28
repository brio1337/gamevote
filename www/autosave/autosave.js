var pg = require('pg');

module.exports = function(app, route, connstr) {
  app.post(route, post);

  function post(req, res) {
    console.log(req.body.autosave);
    var autosave = req.body.autosave;
    var user = req.session.user;
    if (!user) {
      return res.redirect('/login');
    }
    pg.connect(connstr, function(err, client, done) {
      if (err) {
        done();
        return res.status(500).type('text/plain').send(err.toString());
      }
      var sql = 'UPDATE players SET autosave = $1 WHERE player = $2';
      client.query({text: sql, values: [autosave, user]}, function(err, result) {
        done();
        if (err) {
          return res.status(500).type('text/plain').send(err.toString());
        }
        return res.sendStatus(200);
      });
    });
  }
};

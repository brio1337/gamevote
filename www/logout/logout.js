module.exports = function(app, route, connstr) {
  app.post(route, post);

  function post(req, res) {
	  delete req.session.user;
    return res.redirect('/login');
  }

};

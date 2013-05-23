nest = require 'unofficial-nest-api'

exports = module.exports = (app) ->
  # Home
  app.get '/login', (req, res) ->
    res.redirect '/auth/google'

  app.get '/post-login-check', app.gate.requireLogin, (req, res) ->
    console.log req.user.nestAuth
    if req.user.nestAuth?.user and req.user.nestAuth?.pass
      res.redirect '/'
    else
      res.redirect '/nest-auth'

  app.get '/nest-auth', app.gate.requireLogin, (req, res) ->
    res.render 'nest-auth'

  app.post '/nest-auth', app.gate.requireLogin, (req, res) ->
    user = req.user
    nest.login req.body.username, req.body.password, (err, data) ->
      if err
        return res.redirect '/nest-auth?incorrect'

      nest.fetchStatus (data) ->
        console.log data
        user.nestAuth =
          user: req.body.username
          pass: req.body.password
        for deviceId of data.shared
          user.device = deviceId

        app.mirror.timeline.insert(
          resource:
            text: "Welcome to Glass Nest, "+user.name
            menuItems: [
              {
                id: 1
                action: "REPLY"
              },
              {
                id: 2
                action: "DELETE"
              }
            ]
            notification:
              level: "DEFAULT"
          )
          .withAuthClient(user.credentials(app))
          .execute (err, data) ->
            console.log err || data
        user.save()
        res.redirect '/'
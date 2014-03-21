This is about the simplest signalling server I can possibly imagine. It isn't
even remotely designed to scale out to multiple processes or machines.

    require('colors')
    crypto = require('crypto')
    WebSocketServer = require('ws').Server
    express = require('express')
    http = require('http')
    https = require('https')
    _ = require('lodash')
    request = require('request')
    yaml = require('js-yaml')
    fs = require('fs')
    path = require('path')
    socketserver = require('./socketserver.litcoffee')
    passport = require('passport')
    GitHubStrategy = require('passport-github').Strategy

Config me!

    config = yaml.safeLoad(fs.readFileSync(path.join(__dirname, 'config.yaml'), 'utf8'))
    serverConfig = config[process.env['HOST'] or 'localhost:9001']
    port = process.env['PORT'] or 9000

Static service of the single page app, with passport authentication.

    app = express()
    app.use(parser = express.cookieParser('--++--'))
    store = new express.session.MemoryStore()
    store.parser = parser
    app.use(express.session(store: store, key: 'sid'))
    passport.use(new GitHubStrategy({
      clientID: serverConfig.github.clientid
      clientSecret: serverConfig.github.clientsecret
      callbackURL: serverConfig.github.callback
    }, (access, refresh, profile, done) -> done(undefined, profile))
    )
    app.use(passport.initialize())
    app.use(passport.session())
    app.get '/auth/github', passport.authenticate('github'), (req, res) ->
    app.get '/auth/github/callback', passport.authenticate('github', failuserRedirect: '/#fail'), (req, res) ->
      res.redirect '/'
    app.get '/auth/logout', (req, res) ->
      req.logout()
      res.redirect '/'

Route service.

    app.use(app.router)
    app.use(express.static("#{__dirname}/../build"))

Passport handling, there is no local use database, but we have to use session
in order to be able to get back the user profile.

    passport.serializeUser (user, done) ->
      done undefined, user
    passport.deserializeUser (data, done) ->
      done undefined, data

HTTP + WS service, this will be proxied with HTTPS live for production.

    server = http.createServer(app)
    server.listen(port)
    ws = new WebSocketServer(server: server)
    socketserver(ws, config, store)
    console.log 'HTTP/WS listening on', "#{port}".blue

Self Signed SSL for local development, this makes it so the camera permission
saves.

    sslOptions =
      key: fs.readFileSync('var/privatekey.pem').toString()
      cert: fs.readFileSync('var/certificate.pem').toString()
    secureServer = https.createServer(sslOptions, app)
    secureServer.listen(port+1)
    wss = new WebSocketServer(server: secureServer)
    socketserver(wss, config, store)
    console.log 'HTTPS listening on', "#{port+1}".blue


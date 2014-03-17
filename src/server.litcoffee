
This is about the simplest signalling server I can possibly imagine. It isn't
even remotely designed to scale out to multiple processes or machines.

    require('colors')
    crypto = require('crypto')
    uuid = require('node-uuid')
    WebSocketServer = require('ws').Server
    express = require('express')
    http = require('http')
    https = require('https')
    _ = require('lodash')
    hummingbird = require('hummingbird')
    request = require('request')
    yaml = require('js-yaml')
    fs = require('fs')
    path = require('path')
    socketserver = require('./socketserver.litcoffee')

Config me!

    config = yaml.safeLoad(fs.readFileSync(path.join(__dirname, 'config.yaml'), 'utf8'))
    port = process.env['PORT'] or 9000

Track running sockets to get a sense of all sessions

    sockets = {}

index all the profiles for autocomplete

    profileIndex = null

    reindex = (sockets) ->
      fields = (doc) ->
        ret = []
        ret.push doc.userprofiles.github.name
        ret.push doc.userprofiles.github.login
        ret.join ' '
      profileIndex = new hummingbird.Index()
      profileIndex.by_gravatar_id = {}
      profileIndex.by_github_id = {}

      for id, socket of sockets
        if socket.userprofiles.github
          console.log 'indexing'.yellow, id, socket.userprofiles.github.id
          socket.userprofiles.github.id = "#{socket.userprofiles.github.id}"
          doc =
            id: id
            sessionid: id
            userprofiles: socket.userprofiles
          profileIndex.add doc, false, fields
          profileIndex.by_github_id["#{socket.userprofiles.github.id}"] = doc
          profileIndex.by_gravatar_id["#{socket.userprofiles.github.gravatar_id}"] = doc

Static service of the single page app.

    app = express()
    app.use(express.static("#{__dirname}/../build"))

Service here, HTTP for the client single page along with ws for the signalling.

    server = http.createServer(app)
    server.listen(port)
    ws = new WebSocketServer(server: server)
    socketserver(ws, config, sockets, profileIndex, reindex)
    console.log 'HTTP/WS listening on', "#{port}".blue

Self Signed SSL for local development, this makes it so the camera permission
saves.

    sslOptions =
      key: fs.readFileSync('var/privatekey.pem').toString()
      cert: fs.readFileSync('var/certificate.pem').toString()
    secureServer = https.createServer(sslOptions, app)
    secureServer.listen(port+1)
    wss = new WebSocketServer(server: secureServer)
    socketserver(wss, config, sockets, profileIndex, reindex)
    console.log 'HTTPS listening on', "#{port+1}".blue


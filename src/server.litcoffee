This is about the simplest signalling server I can possibly imagine. It isn't
even remotely designed to scale out to multiple processes or machines.

    require('colors')
    crypto = require('crypto')
    WebSocketServer = require('ws').Server
    express = require('express')
    http = require('http')
    https = require('https')
    _ = require('lodash')
    yaml = require('js-yaml')
    fs = require('fs')
    path = require('path')
    socketserver = require('./socketserver.litcoffee')

Config me!

    serverConfig = yaml.safeLoad(fs.readFileSync(path.join(__dirname, 'config.yaml'), 'utf8'))
    port = process.env['PORT'] or 9000
    sslport = process.env['SSLPORT'] or 9001

Static service of the single page app, with WebSockets.

    app = express()
    app.use(express.static(path.join __dirname, "../build"))
    app.use('/node_modules', express.static(path.join __dirname, "../node_modules"))
    app.get '/screen', (req, res, next) ->
      res.sendfile path.join __dirname, '../build/screen.html'

HTTP + WS service, this will be proxied with HTTPS live for production.

    server = http.createServer(app)
    server.listen(port)
    ws = new WebSocketServer(server: server)
    socketserver(ws, serverConfig)
    console.log 'HTTP/WS listening on', "#{port}".blue

Self Signed SSL for local development, this makes it so the camera permission
saves.

    sslOptions =
      key: fs.readFileSync('var/privatekey.pem').toString()
      cert: fs.readFileSync('var/certificate.pem').toString()
    secureServer = https.createServer(sslOptions, app)
    secureServer.listen(sslport)
    wss = new WebSocketServer(server: secureServer)
    socketserver(wss, serverConfig)
    console.log 'HTTPS listening on', "#{sslport}".blue


All the socket handling, packed into a function that hooks on to a ws
socket server.

    _ = require('lodash')
    uuid = require('node-uuid')
    yaml = require('js-yaml')

Track running sockets to get a sense of all sessions.

    sockets = {}

    module.exports = (wss, config, store) ->

Bad news straight to the console

      wss.on 'error', (error) ->
        console.error "#{error}".red

Sockety goodness.

      wss.on 'connection', (socket) ->

User profiles for this connected client socket.

        socket.userprofiles = {}

Get at the session, this bridges OAuth into the socket.

        store.parser socket.upgradeReq, null, (err) ->
          socket.sessionid = socket.upgradeReq.signedCookies['sid']
          store.get socket.sessionid, (err, session) ->
            console.log "#{err}".red if err
            github = JSON.parse(session?.passport?.user?._raw or '{}')
            if github.id
              console.log "hi there #{github.name}".blue
              socket.userprofiles.github = github
            else
              delete socket.userprofiles.github

Signal -- send a message back to the connected client.

        socket.signal = (type, detail) ->
          message =
            type: type
            detail: detail or {}
          console.log '<-'.green, yaml.safeDump(message), '\n---'.green
          message = JSON.stringify(message)
          socket.send message, (err) ->
            if err
              console.log "#{err}".red

Send a hello on a connection.

        socket.signal 'hello'

Translate messages into events allowing declarative event handling.

        socket.on 'message', (req) ->
          try
            message = JSON.parse(req)
            console.log '->'.blue, yaml.safeDump(message), '\n---'.blue
            socket.clientid = message.clientid
            socket.emit message.type, message.detail
          catch error
            console.error "#{error}".red

Client setup, captures the identifier so this client can be called if found.
This identifier is separate from any oauth identifier, and is randomly generated
by each client. This allows you to log on from multiple locations, and thus call
yourself at different locations. And it means you can clear out your local
storage on any client and get a different identifier, providing for privacy.

This is a problem if two clients allocate the same identifier, so clients need
to protect users by creating a nice big random string that is hard to guess.

        socket.on 'register', (user) ->
          if sockets[socket.clientid] and sockets[socket.clientid] isnt socket
            socket.signal 'disconnect'
          else
            sockets[socket.clientid] = socket
            if user.userprofiles.github
              socket.userprofiles = user.userprofiles
              for id, socket of sockets
                socket.signal 'online',
                  clientid: socket.clientid
                  userprofiles: user.userprofiles

Provide configuration to the client. This is used to keep OAuth a bit more secret, though
at the moment these configs are just checked in.

            if config[user.runtime]
              socket.runtime = user.runtime
              socket.signal 'configured', _.extend(config[socket.runtime], sessionid: socket.sessionid, userprofiles: socket.userprofiles)
            else
              console.log "There was no config prepared for #{user.runtime}".yellow

Send WebRTC negotiation along to all peers and let them process it, this will
reflect ice back to the sender, this allows self-calling for testing.

        signalRTC = (type, detail) ->
          fromSocket = sockets[detail.fromclientid]
          toSocket = sockets[detail.toclientid]
          if fromSocket
            fromSocket.signal type, detail
          if toSocket
            toSocket.signal type, detail
        socket.on 'ice', (detail) -> signalRTC('ice', detail)
        socket.on 'offer', (detail) -> signalRTC('offer', detail)
        socket.on 'answer', (detail) -> signalRTC('answer', detail)

Start off a call, the job here is to figure if the called person exists, then
send along messages to start peer to peer call setup on the inbound (caller)
and outbound (callee) side the client ends up doing the bulk of the work, this
is just matchmaking.

This sends along the *flipside* `profiles` so that clients have enough
data to make a gravatar placeholder or caption with a name.

The one 'rule' here is that you only get one call from-to.

This has a special case for debugging if you call 'fail' which sets up an
outbound call to nobody to test failing RTC negotiation.

Calls are made 'from' a caller 'to' a callee. The caller is will set up
an 'outboundcall', the callee will set up an 'inboundcall'. Part of this setup
is double checking if a call already exists.

        socket.on 'call', (detail) ->

          if detail.to is 'fail'
            outboundcall =
              outbound: true
              toclientid: 'fail'
              fromclientid: 'fail'
              userprofiles: socket.userprofiles
            socket.signal 'outboundcall', outboundcall

          tosocket = sockets[detail.to]
          if tosocket
            console.log "connecting #{socket.clientid} to #{tosocket.clientid}".blue
            outboundcall =
              id: uuid.v1()
              outbound: true
              fromclientid: socket.clientid
              toclientid: tosocket.clientid
              userprofiles: tosocket.userprofiles
            inboundcall =
              id: uuid.v1()
              inbound: true
              fromclientid: socket.clientid
              toclientid: tosocket.clientid
              userprofiles: socket.userprofiles
            socket.signal 'outboundcall', outboundcall
            tosocket.signal 'inboundcall', inboundcall

Hanging up is pretty simple, just ask both potential socket sides to do so.

        socket.on 'hangup', (call) ->
          fromsocket = sockets[call.fromclientid]
          tosocket = sockets[call.toclientid]
          if fromsocket
            fromsocket.signal 'hangup', call
          if tosocket
            tosocket.signal 'hangup', call

Presence queries, this comes back with a 'user object', which is an entire
hash of userprofiles.

        socket.on 'isonline', (user) ->
          _(sockets)
            .values()
            .select (othersocket) -> othersocket.userprofiles?.github?.id is user?.github?.id
            .forEach (othersocket) -> othersocket.signal 'online',
              clientid: othersocket.clientid
              userprofiles: othersocket.userprofiles

Close removes the socket from tracking and the index.

        socket.on 'close', ->
          try
            if sockets[socket.clientid] is socket
              delete sockets[socket.clientid]
              reindex(sockets)
          catch error
            console.error error.red


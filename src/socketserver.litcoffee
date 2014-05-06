All the socket handling, packed into a function that hooks on to a ws
socket server.

    _ = require('lodash')
    uuid = require('node-uuid')
    fs = require('fs')
    path = require('path')
    yaml = require('js-yaml')

Track running sockets to get a sense of all sessions.

    sockets = {}

All rooms, made up by users on the fly.

    rooms = {}

    module.exports = (wss, config) ->

Bad news straight to the console

      wss.on 'error', (error) ->
        console.error "#{error}".red

Sockety goodness, here are all the event handlers on a per socket basis.

      wss.on 'connection', (socket) ->

Track all the screens pushed from this socket. So, when a socket disconnects,
the screens all go with it.

        socket.screens = {}

Signal -- send a message back to the connected client, this patches a method
directly on to the socket that follows our type/detail protocol that makes
WebSocket messages essentially the same as DOM events.

        socket.signal = (type, detail) ->
          message =
            type: type
            detail: detail or {}
          console.log '<-'.green, yaml.safeDump(message), '\n---'.green unless detail?.nolog
          message = JSON.stringify(message)
          socket.send message, (err) ->
            if err
              console.log "#{err}".red

Update everyone in the room with the current room state. This is a list of
client identifiers that informs a connected client session who it may need
to call or disconnect.

        roomChanged = ->
          _.each rooms[socket.room], (peerSocket) ->
            try
              peerSocket.signal 'roomlist',
                _(rooms[socket.room])
                  .values()
                  .map (s) -> s.clientid
                  .value()
              peerSocket.signal 'roomscreens',
                _(rooms[socket.room])
                  .values()
                  .map (s) -> s.screens
                  .map (s) -> _.values(s)
                  .flatten()
                  .value()
            catch err
              console.log "#{err}".red


Translate messages into events allowing declarative event handling. This is
in charge of setting up the `clientid` on to socket, but not registering in
`sockets`.

        socket.on 'message', (req) ->
          try
            message = JSON.parse(req)
            console.log '->'.blue, yaml.safeDump(message), '\n---'.blue unless message?.detail?.nolog
            socket.clientid = message.clientid
            socket.emit message.type, message.detail
          catch error
            console.error "#{error}".red

Client setup, captures the identifier so this client can be called if found.
This identifier is randomly generated by each client. This allows you to log on
from multiple locations, and thus call yourself at different locations. And it
means you can clear out your local storage on any client and get a different
identifier, providing for privacy.

This is a problem if two clients allocate the same identifier, so clients need
to protect users by creating a nice big random string that is hard to guess.

Rooms are simply a hash of sockets in the room. This lets you send messages
along to just the members of the room easily, since every socket is marked
with both a client and a room. So -- this means any given socket can only
be in one room. For sure!

        socket.on 'register', (user) ->
          sockets[socket.clientid] = socket
          if user.room
            delete rooms?[socket.room]?[socket.clientid]
            roomChanged()
            socket.room = user.room
            rooms[socket.room] ?= {}
            rooms[socket.room][socket.clientid] = socket
            roomChanged()

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

Start off a call, the job here is to figure if the called client exists, then
send along messages to start peer to peer call setup on the inbound (caller)
and outbound (callee) side the client ends up doing the bulk of the work, this
is just matchmaking.

This has a special case for debugging if you call 'fail' which sets up an
outbound call to nobody to test failing RTC negotiation.

Calls are made 'from' a caller 'to' a callee. The caller is will set up
an 'outboundcall', the callee will set up an 'inboundcall'.

        socket.on 'call', (detail) ->
          tosocket = sockets[detail.to]
          callid = uuid.v1()
          if tosocket
            console.log "connecting #{socket.clientid} to #{tosocket.clientid}".blue
            outboundcall =
              outbound: true
              callid: callid
              fromclientid: socket.clientid
              toclientid: tosocket.clientid
              config: config
            inboundcall =
              inbound: true
              callid: callid
              fromclientid: socket.clientid
              toclientid: tosocket.clientid
              config: config
            socket.signal 'outboundcall', outboundcall
            tosocket.signal 'inboundcall', inboundcall

Ping handling comes back with a version hash, allowing clients to know when they
are out of date.

        socket.on 'ping', ->
          hashes = yaml.safeLoad(fs.readFileSync(path.join(__dirname, '..', 'build', 'hashmap.json'), 'utf8'))
          hashes.nolog = true
          socket.signal 'pong', hashes

Handle incoming shared screens. These get registered into the room, but are removed
when the socket goes away, so they aren't as sticky as calls, so we put them
on the client.

        socket.on 'screen', (screen) ->
          socket.screens[screen.screenid] = screen
          roomChanged()
        socket.on 'deletescreen', (screen) ->
          delete socket.screens[screen.screenid]
          roomChanged()

Handle a connection to a shared screen. This is a bit different than a `call` as
it pulls the screen, asking the sharer to start the outbound side.

        socket.on 'callscreen', (detail) ->
          fromsocket = sockets[detail.fromclientid]
          if fromsocket
            console.log "connecting #{socket.clientid} to #{fromsocket.clientid} screen #{detail.screenid}".blue
            outboundcall =
              outbound: true
              screenid: detail.screenid
              fromclientid: fromsocket.clientid
              toclientid: socket.clientid
              config: config
            inboundcall =
              inbound: true
              screenid: detail.screenid
              fromclientid: fromsocket.clientid
              toclientid: socket.clientid
              config: config
            fromsocket.signal 'outboundscreen', outboundcall
            socket.signal 'inboundscreen', inboundcall

Close removes the socket from tracking, but make sure to only remove yourself.

        socket.on 'close', ->
          try
            if sockets[socket.clientid] is socket
              delete sockets[socket.clientid]
              delete rooms[socket.room][socket.clientid]
              roomChanged()
          catch error
            console.error "#{error}".red

All set up!  Send a hello on a connection, this tells the client to get going.

        socket.signal 'hello'

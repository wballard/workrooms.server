All the socket handling, packed into a function that hooks on to a ws
socket server.

    _ = require('lodash')
    uuid = require('node-uuid')
    yaml = require('js-yaml')
    hummingbird = require('hummingbird')

Track running sockets to get a sense of all sessions.

    sockets = {}

Index all the profiles for autocomplete.

    profileIndex = null

    reindex = (sockets) ->
      fields = (doc) ->
        ret = []
        ret.push doc.userprofiles.github?.name
        ret.push doc.userprofiles.github?.login
        ret.join ' '
      profileIndex = new hummingbird.Index()
      profileIndex.by_gravatar_id = {}
      profileIndex.by_github_id = {}

      for id, socket of sockets
        if socket.userprofiles?.github?.id
          console.log 'indexing'.yellow, id, socket.userprofiles.github.id, socket.clientid
          socket.userprofiles.github.id = "#{socket.userprofiles.github.id}"
          doc =
            id: id
            clientid: id
            userprofiles: socket.userprofiles
          profileIndex.add doc, false, fields
          profileIndex.by_github_id["#{socket.userprofiles.github.id}"] = doc
          profileIndex.by_gravatar_id["#{socket.userprofiles.github.gravatar_id}"] = doc

    module.exports = (wss, config, store) ->

Bad news straight to the console

      wss.on 'error', (error) ->
        console.error "#{error}".red

Sockety goodness.

      wss.on 'connection', (socket) ->

User profiles for this connected client socket.

        socket.userprofiles = {}

Track calls, this is used to route messages between peers.

        socket.calls = []

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

Client setup, captures the identifier so this client can be called if found. This
will allow for a 'refresh' of existing calls if the server knows of calls that
the client simply does not. Allows the client side view to be reloaded by users
as a manual error recovery.

        socket.on 'register', (detail) ->
          if sockets[socket.clientid] and sockets[socket.clientid] isnt socket
            socket.signal 'disconnect'
          else
            sockets[socket.clientid] = socket
            for id, socket of sockets
              socket.send 'isonline', detail.userprofiles
            if detail.userprofiles.github
              socket.userprofiles = detail.userprofiles
            calls = detail.calls or []
            if calls.length
              socket.calls = detail.calls
            else
              for call in socket.calls
                if call.outbound
                  socket.signal 'outboundcall', call
                if call.inbound
                  socket.signal 'inboundcall', call
            reindex(sockets)

Provide configuration to the client. This is used to keep OAuth a bit more secret, though
at the moment these configs are just checked in.

            if config[detail.runtime]
              socket.runtime = detail.runtime
              socket.signal 'configured', _.extend(config[socket.runtime], sessionid: socket.sessionid, userprofiles: socket.userprofiles)
            else
              console.log "There was no config prepared for #{detail.runtime}".yellow

Send WebRTC negotiation along to all peers and let them process it, this will
reflect ice back to the sender, this allows self-calling for testing.

        signalRTC = (type, detail) ->
          _(sockets)
            .values()
            .select((socket) -> _.any(socket.calls, (call) -> call.callid is detail.callid))
            .forEach (socket) ->
              socket.signal type, detail
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

And -- the autoconference, when you call someone, you are really calling everyone
they are talking to -- virtually walking up to their desk. This may require a 
bit of a ban on self calls to work. **TODO**

        socket.on 'call', (detail) ->
          callid = uuid.v1()

          if detail.to is 'fail'
            outboundcall =
              outbound: true
              callid: callid
              clientid: 'fail'
              userprofiles: socket.userprofiles
            socket.calls.push outboundcall
            socket.signal 'outboundcall', outboundcall

          tosocket = sockets[detail.to]
          if tosocket
            if _.any(socket.calls, (call) -> call.toclientid is detail.to)
              console.log "already connected #{socket.clientid} to #{tosocket.clientid}".yellow
            else
              autoconference_peers = []
              tosocket.calls.forEach (call) ->
                autoconference_peers.push call.fromclientid
                autoconference_peers.push call.toclientid
              console.log "connecting #{socket.clientid} to #{tosocket.clientid}".blue
              outboundcall =
                id: uuid.v1()
                outbound: true
                callid: callid
                fromclientid: socket.clientid
                toclientid: tosocket.clientid
                userprofiles: tosocket.userprofiles
              inboundcall =
                id: uuid.v1()
                inbound: true
                callid: callid
                fromclientid: socket.clientid
                toclientid: tosocket.clientid
                userprofiles: socket.userprofiles
              socket.calls.push outboundcall
              socket.signal 'outboundcall', outboundcall
              tosocket.calls.push inboundcall
              tosocket.signal 'inboundcall', inboundcall

Hang up all calls known to this socket. This means the counterparty needs
to be informed, which is done by transplanting the event over to the other 
sockets.

Search for the call to actuall hang up is by callid, so that makes it OK
for either the inbound or the outbound side to be sent to either peer.

If a call is found to actually remove, it is echoed back with another hangup
message. This works symmetrically, letting the other peer get a message back to
the client.

        socket.on 'hangup', (hangupCall) ->
          socket.signal 'hangup', hangupCall
          hangupCalls =  _.remove(socket.calls, (x) -> x?.callid is hangupCall.callid)
          _.forEach hangupCalls, (call) ->
            sockets?[call?.fromclientid]?.emit 'hangup', call
            sockets?[call?.toclientid]?.emit 'hangup', call

Directory search.

        socket.on 'autocomplete', (detail) ->
          profileIndex?.search detail.search, (results) ->
            console.log results
            socket.signal 'autocomplete',
              search: detail.search
              results: results

Presence queries.

        socket.on 'isonline', (detail) ->
          userprofiles =
            profileIndex.by_gravatar_id[detail?.userprofiles?.github?.gravatar_id] or
            profileIndex.by_github_id[detail?.userprofiles?.github?.id]
          if userprofiles
            socket.signal 'online', userprofiles

Close removes the socket from tracking and the index.

        socket.on 'close', ->
          try
            if sockets[socket.clientid] is socket
              delete sockets[socket.clientid]
              reindex(sockets)
          catch error
            console.error error.red


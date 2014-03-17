All the socket handling, packed into a function that hooks on to a ws
socket server.

    _ = require('lodash')
    yaml = require('js-yaml')

    module.exports = (wss, config, sockets, profileIndex, reindex) ->

Bad news straight to the console

      wss.on 'error', (error) ->
        console.error "#{error}".red

Sockety goodness.

      wss.on 'connection', (socket) ->

User profiles for this connected client socket.

        socket.userprofiles = {}

Track calls, this is used to route messages between peers.

        socket.calls = []

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
            socket.sessionid = message.from
            socket.emit message.type, message.detail
          catch error
            console.error "#{error}".red

Client setup, captures the identifier so this client can be called if found. This
will allow for a 'refresh' of existing calls if the server knows of calls that
the client simply does not. Allows the client side view to be reloaded by users
as a manual error recovery.

        socket.on 'register', (detail) ->
          sockets[socket.sessionid] = socket
          calls = detail.calls or []
          if calls.length
            socket.calls = detail.calls
          else
            for call in socket.calls
              if call.outbound
                socket.signal 'outboundcall', call
              if call.inbound
                socket.signal 'inboundcall', call

Provide configuration to the client. This is used to keep OAuth a bit more secret, though
at the moment these configs are just checked in.

          if config[detail.runtime]
            socket.runtime = detail.runtime
            socket.signal 'configured', _.extend(config[socket.runtime], sessionid: socket.sessionid, userprofiles: socket.userprofiles)
          else
            console.log "There was no config prepared for #{detail.runtime}".yellow

Client profiles, this is directory data so the client can be found by query.

        socket.on 'userprofile', (userprofile) ->
          sockets[socket.sessionid] = socket
          socket.userprofiles[userprofile.profile_source] = userprofile
          console.log "hi there #{userprofile.name}".blue
          socket.userprofiles.sessionid = socket.sessionid
          socket.signal 'userprofiles', socket.userprofiles
          reindex(sockets)

Validate github authorization tokens.

          if userprofile.profile_source is 'github' and config[userprofile.runtime]
            user = config[userprofile.runtime].github.clientid
            pass = config[userprofile.runtime].github.clientsecret
            options =
              url: "https://api.github.com/applications/#{user}/tokens/#{userprofile.access_token}"
              headers:
                'User-Agent': 'request'
              auth:
                user: user
                pass: pass
            request.get options, (err, response, body) ->
              if response?.statusCode is 200
                console.log "validated #{userprofile.name or userprofile.login}".blue
                userprofile.valid = true
                socket.signal 'valid',
                  userprofiles: socket.userprofiles
                  validation: JSON.parse(body)

Send WebRTC negotiation along to all peers and let them process it, this will
reflect ice back to the sender, this allows self-calling for testing.

        signal = (type, detail) ->
          _(sockets)
            .values()
            .select((socket) -> _.any(socket.calls, (call) -> call.callid is detail.callid))
            .forEach (socket) ->
              socket.signal type, detail
        socket.on 'ice', (detail) -> signal('ice', detail)
        socket.on 'offer', (detail) -> signal('offer', detail)
        socket.on 'answer', (detail) -> signal('answer', detail)

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
              sessionid: 'fail'
              userprofiles: socket.userprofiles
            socket.calls.push outboundcall
            socket.signal 'outboundcall', outboundcall

          tosocket = sockets[detail.to]
          if tosocket
            if _.any(socket.calls, (call) -> call.tosessionid is detail.to)
              console.log "already connected #{socket.sessionid} to #{tosocket.sessionid}".yellow
            else
              autoconference_peers = []
              tosocket.calls.forEach (call) ->
                autoconference_peers.push call.fromsessionid
                autoconference_peers.push call.tosessionid
              console.log "connecting #{socket.sessionid} to #{tosocket.sessionid}".blue
              outboundcall =
                id: uuid.v1()
                outbound: true
                callid: callid
                fromsessionid: socket.sessionid
                tosessionid: tosocket.sessionid
                userprofiles: tosocket.userprofiles
              inboundcall =
                id: uuid.v1()
                inbound: true
                callid: callid
                fromsessionid: socket.sessionid
                tosessionid: tosocket.sessionid
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
          hangupCalls =  _.remove(socket.calls, (x) -> x?.callid is hangupCall.callid)
          _.forEach hangupCalls, (call) ->
            socket.signal 'hangup', call
            if sockets?[call?.fromsessionid]?.readyState is 1
              sockets?[call?.fromsessionid]?.emit 'hangup', call
            if sockets?[call?.tosessionid]?.readyState is 1
              sockets?[call?.tosessionid]?.emit 'hangup', call

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
            profileIndex.by_gravatar_id[detail.gravatar_id] or
            profileIndex.by_github_id[detail.userid]
          if userprofiles
            socket.signal 'online', userprofiles

Close removes the socket from tracking and the index.

        socket.on 'close', ->
          try
            delete sockets[socket.sessionid]
            reindex(sockets)
          catch error
            console.error error.red


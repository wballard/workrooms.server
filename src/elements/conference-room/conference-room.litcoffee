The conference room is a lot like a controller, bringing together
multiple different elements and coordinating them. In particular, this
element is responsible for taking events from `RTCPeerConnection` objects in
scope and sending them along to the signalling server in order to set up
peer-to-peer communication.

This differs from a controller in that only the DOM scoping is used, events
bubble up from contained elements, and messages are send back down
via method calls and property sets. Nice and simple.

#Message Pattern
All calls have an outbound (you call) and an inbound (you were called) side
to match up with WebRTC's expectations.

All calls have a .id which is unique to each call, and is used
as the correlation key between the inbound and outbound side
to set up peer-peer traffic.

##Connecting State
Connecting relays through the server to find another peer to call, and
if possible, sets up a local `outboundcall`. Similarly the called side
gets a `inboundcall`.
```
  (call) -> server
  calling client <- (outboundcall | notavailable)
  called client <- (inboundcall)
```
##Connected State
When connected, calls can be modified by either side by relaying messages
though the signalling server.
**TODO** should these go peer-to-peer instead over a data channel?
```
  (mute | unmute | hangup) -> server
  any client <- (mute | unmute | hangup)
```

#Attributes
##sessionid
This is a unique random guid used to identify this running app to the
signalling server.
##signallingserver
An URL pointing to a WebSocket server used for call signalling.

#Events
##error
Bad things happen. This lets you see when.
##inboundcall
Fired when the server requests that you handle an inbound call.
##outboundcall
Fired when the server requests that you handle an outbound call.

    uuid = require('node-uuid')
    qwery = require('qwery')
    bonzo = require('bonzo')
    config = require('../../config.yaml')?[chrome.runtime.id]

    Polymer 'conference-room',
      attached: ->

Hook up the session identifier and URL pointing to the appropriate signalling
server when ready. This uses the inline config object data.

        @sessionid = uuid.v1()
        @signallingserver = config.signallingServer
        @keepalive = config.keepalive or 30

This is the most important part, setting up the WebSocket to the signalling server. Every message is built up with the `sessionid`.
WebSocket messages are turned into DOM events or delegated to an appropriate
contained call element.

* **TODO** make this an auto-reconnecting socket.
* **TODO** make this buffer messages until the socket is available.

        socket = new WebSocket(@signallingserver)
        signalling = (message) =>
          message.sessionid = @sessionid
          socket.send(JSON.stringify(message))
        socket.onmessage = (evt) =>
          console.log 'signal from server', evt
          try
            message = JSON.parse(evt.data)
            if message.inboundcall?
              @fire 'inboundcall', message
            if message.outboundcall?
              @fire 'outboundcall', message
            forMe = (call) ->
              message.callid is call.callid and message.peerid isnt call.peerid
            qwery('inbound-video-call', @shadowRoot).forEach (call) ->
              call.signal(message) if forMe(call)
            qwery('outbound-video-call', @shadowRoot).forEach (call) ->
              call.signal(message) if forMe(call)
          catch err
            @fire 'error', error: err

The conference room supplies the connection to the signalling server, so it
needs to listen for signal requests from contained calls and forward those along.
        @addEventListener 'signal', (evt) =>
          signalling evt.detail

WebRTC kicks off interaction when it has something to share, namely a local
stream of data to transmit. Listen for this stream and pass it along to call
objects. This kicks off call negotiation with the signalling server.

Oh -- and -- when a local stream is available, make sure to ask if there
are any calls queued up to process!

        @addEventListener 'localstream', (evt) =>
          @localstream = evt.detail.stream
          qwery('outbound-video-call', @shadowRoot).forEach (outbound) =>
            outbound.localStream evt.detail.stream
          qwery('inbound-video-call', @shadowRoot).forEach (inbound) =>
            inbound.localStream evt.detail.stream
          qwery('ui-local-video', @shadowRoot).forEach (s) =>
            s.localStream evt.detail.stream
          chrome.runtime.sendMessage
            dequeueCalls: true

OK -- so this is the tricky bit, it isn't worth asking to connect calls until
the local stream is available.

        chrome.runtime.onMessage.addListener (message, sender, respond) =>
          if message.call and @localstream
            chrome.runtime.sendMessage
              dequeueCalls: true
          if message.makeCalls
            message.makeCalls.forEach (x) =>
              signalling
                call: true
                to: x
                callid: uuid.v1()

Set up inbound and outbound alls when asked by adding an element.

        @addEventListener 'outboundcall', (evt) ->
          url = evt?.detail?.userprofiles?.github?.avatar_url
          bonzo(qwery('.calls', @shadowRoot))
            .append("""<outbound-video-call gravatarurl="#{url}" callid="#{evt.detail.callid}"></outbound-video-call>""")
        @addEventListener 'inboundcall', (evt) ->
          url = evt?.detail?.userprofiles?.github?.avatar_url
          callToast = webkitNotifications.createNotification url, 'Call From', evt.detail.userprofiles.github.name
          callToast.onclick = ->
            chrome.runtime.sendMessage
              showConference: true
          callToast.show()
          bonzo(qwery('.calls', @shadowRoot))
            .append("""<inbound-video-call gravatarurl="#{url}" callid="#{evt.detail.callid}"></inbound-video-call>""")

Video players can ask for the local stream. Actually, they *will* ask for the
local stream. Hook them up.

        @addEventListener 'needlocalstream', (evt) =>
          evt.detail.localStream = @localstream

Keep track of OAuth supplied user profiles, and listen for them coming
in from chrome. Send them along to the signalling server. These profiles
sent to the signalling server build up a directory service dynamically. This
also acts as the keepalive for the WebSocket back to the signalling server.

        userprofiles = {}
        setInterval =>
          signalling userprofiles: @userprofiles
        , @keepalive * 1000
        chrome.runtime.onMessage.addListener (message) =>
          if message.userprofile
            userprofiles[message.userprofile.profile_source] = message.userprofile
            signalling userprofiles: userprofiles

And call control messages for connected calls. This also heartbeats the mute
status, similar to the user profiles.

* *TODO* use peer to peer messaging for the mute controls

        muteStatus =
          sourcemutedvideo: false
          sourcemutedaudio: false
        signalMuteStatus = =>
          bonzo(qwery('outbound-video-call', @shadowRoot)).each (call) ->
            signalling
              sourcemutedaudio: muteStatus.sourcemutedaudio
              sourcemutedvideo: muteStatus.sourcemutedvideo
              callid: call.getAttribute('callid')
              peerid: call.getAttribute('peerid')
        setInterval signalMuteStatus, @keepalive * 1000
        @addEventListener 'audio.on', (evt) ->
          muteStatus.sourcemutedaudio = false
          signalMuteStatus()
        @addEventListener 'audio.off', (evt) ->
          muteStatus.sourcemutedaudio = true
          signalMuteStatus()
        @addEventListener 'video.on', (evt) ->
          muteStatus.sourcemutedvideo = false
          signalMuteStatus()
        @addEventListener 'video.off', (evt) ->
          muteStatus.sourcemutedvideo = true
          signalMuteStatus()
        @addEventListener 'hangup', (evt) =>
          bonzo(qwery("outbound-video-call[callid='#{evt.detail.callid}'", @shadowRoot)).remove()
          bonzo(qwery("inbound-video-call[callid='#{evt.detail.callid}'", @shadowRoot)).remove()

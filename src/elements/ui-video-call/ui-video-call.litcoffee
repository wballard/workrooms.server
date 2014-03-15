Base video call, don't use this tag directly instead this is a
bit of a base element to extend.


#Events
##ice
A NAT traversal message for WebRTC, sent to peers via signalling
##offer
WebRTC message to communicate config and willingness to make a call.
##answer
WebRTC message after an `offer` is accepted, sent back to the originator
of the `offer`.

#Attributes
##callid
This will be the same on both peers of the call.
##config
Settings, most important property is the `iceServers` array, used to communicate
ICE protocol setup.
##localstream
Media stream originating locally, this is communicated to peers.
##remotestream
Media stream beamed over WebRTC from the other peer.
##peerid
This is the identifier of this side of the running call.
##outbound
Flag attribute indicating this is the outbound side of the call.
##inbound
Flag attribute indicating this is the inbound side of the call.

    require('../elementmixin.litcoffee')
    rtc = require('webrtcsupport')
    uuid = require('node-uuid')
    _ = require('lodash')

    RECONNECT_TIMEOUT_THRESHOLD = 3
    RECONNECT_TIMEOUT = 2 * 1000
    KEEPALIVE_TIMEOUT = 1 * 1000

    Polymer 'ui-video-call',

This is a counting sempahore, yeah, hair splitting, but JavaScript has one
thread so this is atomic by definition. Keep alives reset it, missed
reconnect intervals increment it. When it is above the threshold, reconnection
is tried.

      reconnectSemaphore: 0

This is the default implementation until data is connected.

      send: (type, detail) ->

      created: ->
        @peerid = uuid.v1()

Hook up an RTC connection using ice STUN/TURN servers supplied by our
signaling server.

      connect: ->
        config =
          peerConnectionConfig:
            iceServers: @config.iceServers
          peerConnectionContraints:
            optional: [
              {DtlsSrtpKeyAgreement: true},
              {RtpDataChannels: true}
            ]
        @peerConnection =
          new rtc.PeerConnection(
            config.peerConnectionConfig,
            config.peerConnectionContraints)

This is the heart of the matter, hooking into the peer connection
and sending along ice candidates as `signal`.

        #ice candidates just need to be shared with peers
        @peerConnection.onicecandidate = (evt) =>
          @fire 'ice',
            callid: @getAttribute('callid')
            peerid: @peerid
            candidate: evt.candidate

Video streams coming over RTC need to be displayed.

        #display hookup and removal
        @peerConnection.onaddstream = (evt) =>
          @remotestream = evt.stream
        @peerConnection.onremovestream = (evt) =>
          @remotestream = null

If there is a disconnection, get back to initial state.

        @peerConnection.oniceconnectionstatechange = (evt) =>
          if @peerConnection?.iceConnectionState is 'disconnected'
            @disconnect()

Set up a peer-to-peer keep alive timer.

        @keepaliveInterval = setInterval =>
          @send 'callkeepalive',
            callid: @callid
            peerid: @peerid
        , KEEPALIVE_TIMEOUT

On a request to negotiate, send along the offer from the outbound side to
start up the sequence.

        @peerConnection.onnegotiationneeded = (evt) =>
          if @outbound?
            @offer()
          else
            window.debugFakeDrop = =>
              @disconnect()

Data channels for messages that are just between us peers. This turns messages
coming in into DOM events with the `type` `detail` convention of `CustomEvent`.
So you can just make an event fire on a connected peer by saying
```
@send 'nameofevent',
  stuff: true
  things: yep
```
And then handle it remotedly with
```
@addEventListener 'nameofevent', (evt) -> evt.detail ...
```

        @data = @peerConnection.createDataChannel 'sendy', reliable: false
        @data.onopen = =>
          @send = (type, detail) =>
            message =
              type: type
              from: @peerid
              detail: detail
            @data.send JSON.stringify(message)
        @data.onmessage = (evt) =>
          message = JSON.parse(evt.data)
          if message.from isnt @peerid
            @fire message.type, message.detail
        @peerConnection

And let everything go.

      disconnect: ->
        @remotestream = null
        if @keepaliveInterval?
          clearInterval @keepaliveInterval
          @keepaliveInterval = undefined
        try
          @peerConnection?.close()
        catch err

The document acts as an event bus, so we're hooking up events to the document
and the element itself when it is attached to the DOM.

      attached: ->
        @showAnimated()

Call keep alives, when these fail -- it is time to reconnect the call. This is
reall no more complicated than disconnecting and reconnecting, with each side
doing its part as if it was the original call.
Now the tricky part is to keep from *flapping*, so we'll take that reconnection
semaphore down a few more counts to keep it well below the threshold.

        @reconnectInterval = setInterval =>
          if (@reconnectSemaphore++ > RECONNECT_TIMEOUT_THRESHOLD) and @localstream
            console.log 'trying to reconnect'
            @reconnectSemaphore = -(2 * RECONNECT_TIMEOUT_THRESHOLD)
            @disconnect()
            @connect().addStream(@localstream)
        , RECONNECT_TIMEOUT

        @addEventListener 'callkeepalive', (evt) =>
          @reconnectSemaphore = 0

Mute control, bridge this across to peers. This side will do the actual work
of switching off parts of the stream, and then relay to the far side to do the
visual work of updating visual status of the mute.

        @addEventListener 'remoteaudio', (evt) =>
          @remoteaudio = evt.detail.state
        @addEventListener 'remotevideo', (evt) =>
          @remotevideo = evt.detail.state

When the element is removed from the DOM -- really hung up, there is no need
to reconnect any more.

      detached: ->
        @disconnect()
        clearInterval @reconnectInterval

This is the offer startup if we are on the outbound side.

      offer: _.debounce ->
        if @outbound?
          @peerConnection.createOffer (description) =>
            console.log 'offer created', description, @peerConnection
            @peerConnection.setLocalDescription description, =>
              console.log 'offering', description
              @fire 'offer',
                callid: @getAttribute('callid')
                peerid: @peerid
                sdp: description
            , (err) -> console.log err
          , (err) -> console.log err
      , 300

Setting a local stream is what really 'starts' the call, as it triggers the
RTCPeerConnection to start negotiation.

      localstreamChanged: (oldValue, newValue) ->
        if newValue
          @connect().addStream(newValue)

      localaudioChanged: ->
        @send 'remoteaudio', state: @localaudio

      localvideoChanged: ->
        @send 'remotevideo', state: @localvideo

##WebRTC Signal Processing

ICE messages just add in, there is now offer/answer -- just make sure to not
add your own peer side messages.  And make sure it is a server signal, not just
a local ice message. This isn't a *real case*, but it shows up when you call
yourself for testing.

      processIce: (message) ->
        if message.peerid isnt @peerid and message.callid is @callid
          if message.candidate
            console.log 'adding ice', message.candidate
            @peerConnection.addIceCandidate(new rtc.IceCandidate(message.candidate))

Inbound side SDP needs to make sure we get an offer, which it will then answer.

      processOffer: (message) ->
        if @inbound? and message.callid is @callid
          console.log 'offer inbound', message.sdp
          @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp), =>
            console.log 'offer accepted', message.sdp
            @peerConnection.createAnswer (description) =>
              @peerConnection.setLocalDescription description, =>
                console.log 'local set, answering', @getAttribute('callid')
                @fire 'answer',
                  callid: @getAttribute('callid')
                  peerid: @peerid
                  sdp: description
              , (err) -> console.log err
            , (err) -> console.log err
          , (err) -> console.log err

Outbound side needs to take the answer and complete the call.

      processAnswer: (message) ->
        if @outbound? and message.callid is @callid
          console.log 'completing', @getAttribute('callid')
          @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp), (err) ->
            console.log(err) if err


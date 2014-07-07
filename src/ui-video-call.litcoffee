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
##localstream
Media stream originating locally, this is communicated to peers.
##remotestream
Media stream beamed over WebRTC from the other peer. This exists to allow
cross binding into video displays.
##peerid
This is the identifier of this side of the running call.
##call
This is the call metadata object.

    require('./elementmixin.litcoffee')
    rtc = require('webrtcsupport')
    buffered = require('rtc-bufferedchannel')
    stuff = require('./scripts/web-audio.litcoffee')
    uuid = require('node-uuid')
    _ = require('lodash')

    RECONNECT_TIMEOUT_THRESHOLD = 2
    RECONNECT_TIMEOUT = 2 * 1000
    KEEPALIVE_TIMEOUT = 1 * 1000

    Polymer 'ui-video-call',

This is the default implementation until data is connected. Does nothing
except eat the null exception that would happen with this method missing.

      send: (type, detail) ->

      created: ->

This is a counting sempahore, yeah, hair splitting, but JavaScript has one
thread so this is atomic by definition. Keep alives reset it, missed
reconnect intervals increment it. When it is above the threshold, reconnection
is tried.

        @reconnectSemaphore = 0
        @peerid = uuid.v1()

Hook up an RTC connection using ice STUN/TURN servers supplied by our
signaling server.

      connect: ->
        config =
          peerConnectionConfig:
            iceServers: @call.config.iceServers
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
            peerid: @peerid
            fromclientid: @call.fromclientid
            toclientid: @call.toclientid
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
            peerid: @peerid
            fromclientid: @call.fromclientid
            toclientid: @call.toclientid
            localaudio: @localaudio
            localvideo: @localvideo
            localnametag: @localnametag
            locallocation: @locallocation
            nolog: true
        , KEEPALIVE_TIMEOUT

On a request to negotiate, send along the offer from the outbound side to
start up the sequence.

        @peerConnection.onnegotiationneeded = (evt) =>
          @offer() if @call.outbound?

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

        @data = @peerConnection.createDataChannel 'sendy', reliable: true
        @data.onopen = =>
          bc = buffered @data, maxsize: 1024
          @send = (type, detail) =>
            console.log('-->', type, detail) unless detail?.nolog
            message =
              type: type
              from: @peerid
              detail: detail
            bc.send JSON.stringify(message)
          bc.on 'data', (data) =>
            message = JSON.parse(data)
            if message.from isnt @peerid
              @fire message.type, message.detail
              console.log('<--', message.type, message.detail) unless message?.detail?.nolog
          @fire 'connected'
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
        @show()
        @connect() if @hasAttribute 'autoconnect'

Call keep alives, when these fail -- it is time to reconnect the call. This is
reall no more complicated than disconnecting and reconnecting, with each side
doing its part as if it was the original call.
Now the tricky part is to keep from *flapping*, so we'll take that reconnection
semaphore down a few more counts to keep it well below the threshold.

        @reconnectInterval = setInterval =>
          if (@reconnectSemaphore++ > RECONNECT_TIMEOUT_THRESHOLD) and @localstream
            console.log 'trying to reconnect', @call
            @reconnectSemaphore = -(2 * RECONNECT_TIMEOUT_THRESHOLD)
            @disconnect()
            if @localstream
              @connect().addStream(@localstream)
            else
              @connect()
        , RECONNECT_TIMEOUT

On each keepalive, update the reconnect count as well as the audio/video
mute status. These flags are just for visuals, the actual stream is shut
off at the source when muted.

        @addEventListener 'callkeepalive', (evt) =>
          @reconnectSemaphore = 0
          if @remotevideo and @remotevideo isnt evt.detail.localvideo
            @querySelector('ui-video-stream').takeSnapshot()
          @remoteaudio = evt.detail.localaudio
          @remotevideo = evt.detail.localvideo
          @remotenametag = evt.detail.localnametag
          @remotelocation = evt.detail.locallocation

When the element is removed from the DOM -- really hung up, there is no need
to reconnect any more.

      detached: ->
        @disconnect()
        clearInterval @reconnectInterval

This is the offer startup if we are on the outbound side.

      offer: _.debounce ->
        if @call.outbound?
          @peerConnection.createOffer (description) =>
            @peerConnection.setLocalDescription description, =>
              @fire 'offer',
                peerid: @peerid
                fromclientid: @call.fromclientid
                toclientid: @call.toclientid
                sdp: description
            , (err) -> console.log err
          , (err) -> console.log err
      , 300

Setting a local stream is what really 'starts' the call, as it triggers the
RTCPeerConnection to start negotiation.

      localstreamChanged: (oldValue, newValue) ->
        @connect().addStream(newValue) if newValue

##WebRTC Signal Processing
ICE messages just add in, there is now offer/answer -- just make sure to not
add your own peer side messages.  And make sure it is a server signal, not just
a local ice message. This isn't a *real case*, but it shows up when you call
yourself for testing.

      processIce: (message) ->
        if message.peerid isnt @peerid and message.fromclientid is @call.fromclientid and message.toclientid is @call.toclientid
          if message.candidate
            @peerConnection.addIceCandidate(new rtc.IceCandidate(message.candidate))

Inbound side SDP needs to make sure we get an offer, which it will then answer.

      processOffer: (message) ->
        if @call.inbound? and message.fromclientid is @call.fromclientid and message.toclientid is @call.toclientid
          @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp), =>
            @peerConnection.createAnswer (description) =>
              @peerConnection.setLocalDescription description, =>
                @fire 'answer',
                  peerid: @peerid
                  fromclientid: @call.fromclientid
                  toclientid: @call.toclientid
                  sdp: description
              , (err) -> console.log err
            , (err) -> console.log err
          , (err) -> console.log err

Outbound side needs to take the answer and complete the call.

      processAnswer: (message) ->
        if @call.outbound? and message.fromclientid is @call.fromclientid and message.toclientid is @call.toclientid
          @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp), (err) ->
            console.log(err) if err

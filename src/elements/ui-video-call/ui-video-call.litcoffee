Base video call, don't use this tag directly instead this is a
bit of a base element to extend.


#Events
##signal
A message from RTC that needs to be shared with peers via the
signalling server.
##ice
A NAT traversal message for WebRTC, sent to peers via signalling

#Attributes
##peerid
This is the identifier of this side of the running call.
##outbound
Flag attribute indicating this is the outbound side of the call.
##inbound
Flag attribute indicating this is the inbound side of the call.

    rtc = require('webrtcsupport')

    Polymer 'ui-video-call',
      created: ->

Hook up an RTC connection, using Google's stun/turn.

**TODO** make the ice servers configurable.

        config =
          peerConnectionConfig:
            iceServers: [{"url": "stun:stun.l.google.com:19302"}]
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
            peerid: @getAttribute('peerid')
            candidate: evt.candidate

Video streams coming over RTC need to be displayed.

        #display hookup and removal
        @peerConnection.onaddstream = (evt) =>
          @$.player.display evt.stream
        @peerConnection.onremovestream = (evt) =>
          @$.player.display null

      attached: ->

Event handling, up from the controls inline.

        @addEventListener 'dohangup', (evt) =>
          evt.stopPropagation()
          @fire 'hangup',
            callid: @getAttribute('callid')
            peerid: @getAttribute('peerid')

The document acts as an event bus, so we're hooking up events.

ICE messages just add in, there is now offer/answer -- just make sure to not
add your own peer side messages.  And make sure it is a server signal, not just
a local ice message. This isn't a *real case*, but it shows up when you call
yourself for testing.

        document.addEventListener 'ice', (evt) =>
          if evt.detail.candidate and evt.detail.peerid isnt @peerid and event.detail.signal
            @peerConnection.addIceCandidate(new rtc.IceCandidate(evt.detail.candidate))

Inbound side SDP needs to make sure we get an offer, which it will then answer.

        document.addEventListener 'offer', (evt) =>
          message = evt.detail
          if @inbound? and message.signal
            @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp), =>
              @peerConnection.createAnswer (description) =>
                @peerConnection.setLocalDescription description, =>
                  console.log 'local set, answering', @getAttribute('callid')
                  @fire 'answer',
                    callid: @getAttribute('callid')
                    peerid: @getAttribute('peerid')
                    sdp: description
                , (err) -> console.log err
              , (err) -> console.log err
            , (err) -> console.log err

Outbound side needs to take the answer and complete the call.

        document.addEventListener 'answer', (evt) =>
          message = evt.detail
          if @outbound? and message.signal
            console.log 'completing', @getAttribute('callid')
            @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp), (err) -> console.log err

Handle signals from the signaling server.

        document.addEventListener 'signal', (evt) =>
          message = evt.detail

Mute control from the far side. Unfortunately could not see a way to
get this from the stream itself, even though it surely knows it. So, an
out of band signal is used here.

**TODO** just figure out how to do this from the stream itself

          if message.sourcemutedaudio? and message.peerid isnt @peerid
            if message.sourcemutedaudio
              @$.player.setAttribute('sourcemutedaudio')
            else
              @$.player.removeAttribute('sourcemutedaudio')
          if message.sourcemutedvideo? and message.peerid isnt @peerid
            if message.sourcemutedvideo
              @$.player.setAttribute('sourcemutedvideo')
            else
              @$.player.removeAttribute('sourcemutedvideo')

Setting a local stream is what really 'starts' the call, but it is supplied
asynchronously.

      localStreamChanged: (oldValue, newValue) ->
        if newValue
          console.log 'adding local stream', newValue
          @peerConnection.addStream(newValue)
          if @outbound?
            @peerConnection.createOffer (description) =>
              @peerConnection.setLocalDescription description, =>
                console.log 'offering', @getAttribute('callid')
                @fire 'offer',
                  callid: @getAttribute('callid')
                  peerid: @getAttribute('peerid')
                  sdp: description
              , (err) -> console.log err
            , (err) -> console.log err


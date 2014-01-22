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
    uuid = require('node-uuid')

    Polymer 'ui-video-call',
      attached: ->
        @setAttribute 'peerid', uuid.v1()

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


Event handling, up from the controls inline.


        @addEventListener 'hangup', (evt) =>
          evt.stopPropagation()
          @fire 'signal',
            hangup: true
            callid: @getAttribute('callid')
            peerid: @getAttribute('peerid')

Setting a local stream is what really 'starts' the call, but it is supplied
asynchronously.

        @addEventListener 'localstream', (evt) =>
          localStream = evt.detail
          console.log 'adding local stream', localStream
          @peerConnection.addStream(localStream)
          if @outbound?
            @peerConnection.createOffer (description) =>
              @peerConnection.setLocalDescription description, =>
                console.log 'offering', @getAttribute('callid')
                @fire 'signal',
                  offer: true
                  callid: @getAttribute('callid')
                  peerid: @getAttribute('peerid')
                  sdp: description
              , (err) -> console.log err
            , (err) -> console.log err

Handle signals from the signaling server.

ICE messages just add in, there is now offer/answer -- just
make sure to not add your own peer side messages.

        @addEventListener 'ice', (evt) =>
          console.log 'ice?', @peerid, evt.detail.peerid
          if evt?.detail?.candidate and evt?.detail?.peerid isnt @peerid
            console.log 'ice', evt
            @peerConnection.addIceCandidate(new rtc.IceCandidate(evt.detail.candidate))


        @addEventListener 'signal', (evt) =>
          message = evt.detail

Inbound side SDP needs to make sure we get an offer.

          if message.sdp and @inbound? and message.offer
            @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp), =>
              @peerConnection.createAnswer (description) =>
                @peerConnection.setLocalDescription description, =>
                  console.log 'local set, answering', @getAttribute('callid')
                  @fire 'signal',
                    answer: true
                    callid: @getAttribute('callid')
                    peerid: @getAttribute('peerid')
                    sdp: description
                , (err) -> console.log err
              , (err) -> console.log err
            , (err) -> console.log err

Outbound side needs to take the answer and complete the call.

          if message.sdp and @outbound? and message.answer
            console.log 'completing', @getAttribute('callid')
            @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp), (err) -> console.log err


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

Kick things off by asking for the local stream.

      ready: ->
        console.log 'love me some stream'
        @fire 'getlocalstream'

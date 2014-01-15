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
          @fire 'signal',
            callid: @getAttribute('callid')
            peerid: @getAttribute('peerid')
            ice:
              candidate: evt.candidate

Video streams coming over RTC need to be displayed.

        #display hookup and removal
        @peerConnection.onaddstream = (evt) =>
          @$.player.display evt.stream
        @peerConnection.onremovestream = (evt) =>
          @$.player.display null


Event handling, up from the controls inline.

* hangup: send a signal that this call is over

        @addEventListener 'hangup', (evt) =>
          evt.stopPropagation()
          @fire 'signal',
            hangup: true
            callid: @getAttribute('callid')
            peerid: @getAttribute('peerid')

Good to go! Ask for a local stream to kick things off, passing a callback
function to complete the join.
Setting a local stream is what really 'starts' the call.

        @fire 'needlocalstream', (localStream) =>
          @peerConnection.addStream(localStream)
          @localStream localStream

Handle signals from the signaling server.

      signal: (message) ->

The far side has hung up, turn this into a local DOM event so containing
elements on this side know about it. And `close`, like a nice programmer.

        if message.hangup
          @peerConnection.close()
          @fire 'hangup',
            hangup: true
            callid: @getAttribute('callid')
            peerid: @getAttribute('peerid')

Mute control from the far side. Unfortunately could not see a way to
get this from the stream itself, even though it surely knows it. So, an
out of band signal is used here.

**TODO** just figure out how to do this from the stream itself

        if message.sourcemutedaudio?
          if message.sourcemutedaudio
            @$.player.setAttribute('sourcemutedaudio')
          else
            @$.player.removeAttribute('sourcemutedaudio')
        if message.sourcemutedvideo?
          if message.sourcemutedvideo
            @$.player.setAttribute('sourcemutedvideo')
          else
            @$.player.removeAttribute('sourcemutedvideo')

ICE messages are the same on both sides.

        if message.ice
          @peerConnection.addIceCandidate(new rtc.IceCandidate(message.ice.candidate))

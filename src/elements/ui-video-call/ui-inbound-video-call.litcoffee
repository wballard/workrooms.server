WebRTC is very directional, with callers and callees. So, when you want to
talk to someone, you don't meet in the middle. Somebody calls somebody else.

This element listens for an incoming call from another user.

    rtc = require('webrtcsupport')

    Polymer 'ui-inbound-video-call',

Setting the local stream on an inbound call has no specific action.

      localStream: (localStream) ->

Signalling has a lot of action on the inbound side.  It is 'called', so gets
information from the remote side, and then 'answers' with information to
complete the call. All of this goes over the signalling channel, which is
represented here as events.

      signal: (message) ->
        console.log 'inbound signal', message
        if message.sdp
          @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp), =>
            @peerConnection.createAnswer (description) =>
              @peerConnection.setLocalDescription description, =>
                console.log 'answer', description
                @fire 'signal',
                  answer: true
                  callid: @getAttribute('callid')
                  peerid: @getAttribute('peerid')
                  sdp: description
        @super(arguments)

WebRTC is very directional, with callers and callees. So, when you want to
talk to someone, you don't meet in the middle. Somebody calls somebody else.

This element sets up a call from 'you' to another user.

#Methods
##localStream(stream)
Set up this die of the call with a video stream that is 'you'.

    Polymer 'ui-outbound-video-call',

Setting a local stream is what really 'starts' the call, so this is
a great place to hook up the negotiation events.

      localStream: (localStream) ->
        if localStream
          @peerConnection.onnegotiationneeded = =>
            @peerConnection.createOffer (description) =>
              @peerConnection.setLocalDescription description, =>
                @fire 'signal',
                  offer: true
                  callid: @getAttribute('callid')
                  peerid: @getAttribute('peerid')
                  sdp: description
          @peerConnection.addStream(localStream)

Process incoming signal messages from the signalling server. This is
mirror image-ish from the inbound side. The main difference is that
since this side kicks off with creating an offer, but the time the
sequence of signalling exchanges gets here, we are all done and there
are no more messages.

      signal: (message) ->
        if message.sdp
          @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp)
        @super(arguments)

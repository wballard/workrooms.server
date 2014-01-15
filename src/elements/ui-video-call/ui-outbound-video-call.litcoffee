WebRTC is very directional, with callers and callees. So, when you want to
talk to someone, you don't meet in the middle. Somebody calls somebody else.

This element sets up a call from 'you' to another user.

#Methods
##localStream(stream)
Set up this die of the call with a video stream that is 'you'.

    rtc = require('webrtcsupport')

    Polymer 'ui-outbound-video-call',

Ahh... the exicting world of RTC connection negotiation. This has a kickoff
sequence for the calling outbound side that makes an offer, which is signalled
to the called/inbound side on another user's computer via the signalling
service -- here as an event to let the containing conference room do
signalling.

      localStream: (localStream) ->
        @peerConnection.createOffer (description) =>
          @peerConnection.setLocalDescription description, =>
            console.log 'offer', description
            @fire 'signal',
              offer: true
              callid: @getAttribute('callid')
              peerid: @getAttribute('peerid')
              sdp: description
        , (err) -> console.log err

Process incoming signal messages from the signalling server. This is
mirror image-ish from the inbound side. The main difference is that
since this side kicks off with creating an offer, but the time the
sequence of signalling exchanges gets here, we are all done and there
are no more messages.

      signal: (message) ->
        console.log 'outbound signal', message
        if message.sdp
          @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp)
        @super(arguments)

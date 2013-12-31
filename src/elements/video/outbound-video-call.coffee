rtc = require('webrtcsupport')
VideoCall = require('./video-call.coffee')

###
WebRTC is very directional, with callers and callees. So, when you want to
talk to someone, you don't meet in the middle. Somebody calls somebody else.

This element sets up a call from 'you' to another user.
###
class OutboundVideoCall extends VideoCall
  #start the call with a video stream
  call: (localStream) ->
    #the outbound call is in charge or starting the negotiation by making an offer
    @peerConnection.onnegotiationneeded = =>
      @peerConnection.createOffer (description) =>
        @peerConnection.setLocalDescription description, =>
          @fire 'sdp',
            offer: true
            from: @.getAttribute('from')
            to: @.getAttribute('to')
            sdp: description
    #this actually kicks off the process
    @peerConnection.addStream(localStream)
  signal: (message) ->
    if message.ice
      @peerConnection.addIceCandidate(new rtc.IceCandidate(message.ice.candidate))
    if message.sdp
      @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp)

module.exports =
  OutboundVideoCall: document.register 'outbound-video-call', prototype: OutboundVideoCall.prototype
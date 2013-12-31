rtc = require('webrtcsupport')
VideoCall = require('./video-call.coffee')

###
WebRTC is very directional, with callers and callees. So, when you want to
talk to someone, you don't meet in the middle. Somebody calls somebody else.

This element sets up a call from 'you' to another user.

#Events

#HTML Attributes
from: your identity string
to: identity string you are calling
###
class OutboundVideoCall extends VideoCall
  #start the call, this has takes a video steam and a signalling
  #function to communicate with other clients
  #the outbound call is in charge or starting the negotiation by making an offer
  call: (localStream) ->
    @peerConnection.onnegotiationneeded = =>
      console.log 'outbound negotiating'
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
    #and -- flipped, to match the inbound side
    if message.ice
      @peerConnection.addIceCandidate(new rtc.IceCandidate(message.ice.candidate))
    #getting an answer to the offer completes the sequence
    if message.sdp
      @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp)

module.exports =
  OutboundVideoCall: document.register 'outbound-video-call', prototype: OutboundVideoCall.prototype

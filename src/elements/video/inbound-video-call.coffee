rtc = require('webrtcsupport')
VideoCall = require('./video-call.coffee')

###
WebRTC is very directional, with callers and callees. So, when you want to
talk to someone, you don't meet in the middle. Somebody calls somebody else.

This element listens for an incoming call from another user.
###
class InboundVideoCall extends VideoCall
  #listen for and incoming call with a local video stream
  localStream: (localStream) ->
    if localStream
      @peerConnection.addStream(localStream)
  #Handle an inbound signal message, this is either an ice message, or an sdp
  #message -- ice is easy, you just add it, sdp has an offer/answer mechanism
  #that makes a bit of a callback pyramid, and you need to make sure to send
  #back a proper 'answer' to the 'offer'
  signal: (message) ->
    if message.ice
      @peerConnection.addIceCandidate(new rtc.IceCandidate(message.ice.candidate))
    #inbound calls answer the offer, this matches up with the negotiation on
    #the outbound side
    if message.sdp
      @peerConnection.setRemoteDescription new rtc.SessionDescription(message.sdp), =>
        @peerConnection.createAnswer (description) =>
          @peerConnection.setLocalDescription description, =>
            @fire 'signal',
              answer: true
              callid: @getAttribute('callid')
              peerid: @getAttribute('peerid')
              sdp: description
    super message
module.exports =
  InboundVideoCall: document.register 'inbound-video-call', prototype: InboundVideoCall.prototype

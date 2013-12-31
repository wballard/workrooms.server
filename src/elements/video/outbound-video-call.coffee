Platform = require('polyfill-webcomponents')
require('./style.less')
attachMediaStream = require('attachmediastream')
webrtcSupport = require('webrtcsupport')
mixin = require('../mixin.coffee')

###
WebRTC is very directional, with callers and callees. So, when you want to
talk to someone, you don't meet in the middle. Somebody calls somebody else.

This element sets up a call from 'you' to another user.

#Events

#HTML Attributes
from: your identity string
to: identity string you are calling
###
class OutboundVideoCall extends HTMLElement
  createdCallback: ->
    mixin @
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = '<video id="display"></video>'
  #start the call, this has takes a video steam and a signalling
  #function to communicate with other clients
  call: (signalling, localStream) ->
    @config =
      peerConnectionConfig:
        iceServers: [{"url": "stun:stun.l.google.com:19302"}]
      peerConnectionContraints:
        optional: [
          {DtlsSrtpKeyAgreement: true},
          {RtpDataChannels: true}
        ]
    @peerConnection = new webrtcSupport.PeerConnection(@config.peerConnectionConfig, @config.peerConnectionContraints)
    @peerConnection.onicecandidate = (evt) =>
      signalling
        from: @.getAttribute('from')
        to: @.getAttribute('to')
        outbound: true
        ice:
          candidate: evt.candidate
    @peerConnection.onnegotiationneeded = =>
      console.log 'outbound negotiating'
      @peerConnection.createOffer (description) =>
        @peerConnection.setLocalDescription description, =>
          console.log 'offering', description
          signalling
            from: @.getAttribute('from')
            to: @.getAttribute('to')
            sdp: description
    @peerConnection.onaddstream = (evt) =>
      console.log 'outbound'
      display = @shadow.querySelector('#display')
      attachMediaStream evt.stream, display
    signalling
      from: @.getAttribute('from')
      ping: true
    #this actually kicks off the process
    @peerConnection.addStream(localStream)
  signal: (signalling, message) ->
    #and -- flipped, to match the inbound side
    if message.ice and message.inbound and message.from is @.getAttribute('to') and message.to is @.getAttribute('from')
      @peerConnection.addIceCandidate(new webrtcSupport.IceCandidate(message.ice.candidate))
    if message.sdp and message.sdp.type is 'answer' and message.from is @.getAttribute('to') and message.to is @.getAttribute('from')
      @peerConnection.setRemoteDescription new webrtcSupport.SessionDescription(message.sdp), =>
        console.log @peerConnection

module.exports =
  OutboundVideoCall: document.register 'outbound-video-call', prototype: OutboundVideoCall.prototype

Platform = require('polyfill-webcomponents')
require('./style.less')
attachMediaStream = require('attachmediastream')
webrtcSupport = require('webrtcsupport')
mixin = require('../mixin.coffee')

###
WebRTC is very directional, with callers and callees. So, when you want to
talk to someone, you don't meet in the middle. Somebody calls somebody else.

This element listens for an incoming call from another user.

#Events

#HTML Attributes
from: identity string making the call, i.e. not you
to: you identity string
###
class InboundVideoCall extends HTMLElement
  createdCallback: ->
    mixin @
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = '<video id="display"></video>'
  #listen for and incoming call, this sets up state and sends along messages
  #to the signalling server
  listen: (signalling, localStream) ->
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
      #flip the to and from on the inbound side
      signalling
        from: @.getAttribute('to')
        to: @.getAttribute('from')
        inbound: true
        ice:
          candidate: evt.candidate
    @peerConnection.onaddstream = (evt) =>
      console.log 'inbound'
      display = @shadow.querySelector('#display')
      attachMediaStream evt.stream, display
    signalling
      from: @.getAttribute('to')
      ping: true
    #this actually kicks off the process
    @peerConnection.addStream(localStream)
  #Handle an inbound signal message, this is either an ice message, or an sdp
  #message -- ice is easy, you just add it, sdp has an offer/answer mechanism
  #that makes a bit of a callback pyramid, and you need to make sure to send
  #back a proper 'answer' to the 'offer'
  signal: (signalling, message) ->
    if message.ice and message.outbound and message.from is @.getAttribute('from') and message.to is @.getAttribute('to')
      @peerConnection.addIceCandidate(new webrtcSupport.IceCandidate(message.ice.candidate))
    if message.sdp and message.sdp.type is 'offer' and message.from is @.getAttribute('from') and message.to is @.getAttribute('to')
      @peerConnection.setRemoteDescription new webrtcSupport.SessionDescription(message.sdp), =>
        @peerConnection.createAnswer (description) =>
          @peerConnection.setLocalDescription description, =>
            console.log 'answering', description
            signalling
              from: @.getAttribute('to')
              to: @.getAttribute('from')
              sdp: description

module.exports =
  InboundVideoCall: document.register 'inbound-video-call', prototype: InboundVideoCall.prototype

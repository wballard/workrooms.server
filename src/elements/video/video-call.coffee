Platform = require('polyfill-webcomponents')
attachMediaStream = require('attachmediastream')
rtc = require('webrtcsupport')
require('./style.less')
mixin = require('../mixin.coffee')
bean = require('bean')
uuid = require('node-uuid')

###
Oh man, I'm making a base class, the copy paste was just getting to me

#Events
sdp: a session message for WebRTC, used in signalling
ice: a NAT traversal message for WebRTC, sent to peers via signalling

#HTML Attributes
callid: this is the identifier of the running call
###
class VideoCall extends HTMLElement
  createdCallback: ->
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = '<video id="display"></video>'
  enteredViewCallback: =>
    @setAttribute 'peerid', uuid.v1()
    #hook up a connection, using google's public NAT busting
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
    #ice candidates just need to be shared with peers
    @peerConnection.onicecandidate = (evt) =>
      @fire 'ice',
        callid: @getAttribute('callid')
        peerid: @getAttribute('peerid')
        ice:
          candidate: evt.candidate
    #display hookup and removal
    @peerConnection.onaddstream = (evt) =>
      display = @shadow.querySelector('#display')
      attachMediaStream evt.stream, display
    @peerConnection.onremovestream = (evt) =>
      display = @shadow.querySelector('#display')
      display.src = ''
    @fire 'needlocalstream', @

module.exports =
  VideoCall = VideoCall

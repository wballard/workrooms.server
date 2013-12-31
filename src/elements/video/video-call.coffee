Platform = require('polyfill-webcomponents')
attachMediaStream = require('attachmediastream')
rtc = require('webrtcsupport')
require('./style.less')
mixin = require('../mixin.coffee')
bean = require('bean')
uuid = require('node-uuid')

#Oh man, I'm making a base class, the copy paste was just getting to me
class VideoCall extends HTMLElement
  createdCallback: ->
    mixin @
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
        from: @getAttribute('from')
        to: @getAttribute('to')
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

module.exports =
  VideoCall = VideoCall

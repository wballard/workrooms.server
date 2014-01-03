Platform = require('polyfill-webcomponents')
attachMediaStream = require('attachmediastream')
rtc = require('webrtcsupport')
mixin = require('../mixin.coffee')
uuid = require('node-uuid')
require = require('./video-tool-bar.coffee')
###
Oh man, I'm making a base class, the copy paste was just getting to me

# Events
sdp: a session message for WebRTC, used in signalling
ice: a NAT traversal message for WebRTC, sent to peers via signalling

# HTML Attributes
callid: this is the identifier of the running call
###
class VideoCall extends HTMLElement
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
    <div class="tile video">
      <div>
        <video id="display"></video>
        <video-tool-bar>
          <video-tool icon="fa-phone fa-rotate-135" action="hangup"></video-tool>
        </video-tool-bar>
      </div>
    </div>
    """
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
      @fire 'signal',
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
    #tack on call details to make a useful message
    @shadow.addEventListener 'hangup', (evt) =>
      evt.stopPropagation()
      @fire 'signal',
        hangup: true
        callid: @getAttribute('callid')
        peerid: @getAttribute('peerid')
    #kick it off, asking for a local stream
    @fire 'needlocalstream', @
  signal: (message) ->
    if message.hangup
      @peerConnection.close()
      @fire 'hangup',
        hangup: true
        callid: @getAttribute('callid')
        peerid: @getAttribute('peerid')

module.exports =
  VideoCall = VideoCall

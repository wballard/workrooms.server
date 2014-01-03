platform = require('polyfill-webcomponents')
rtc = require('webrtcsupport')
mixin = require('../mixin.coffee')
uuid = require('node-uuid')
require('./ui-video-stream.coffee')
require('./ui-video-toolbar.coffee')

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
        <ui-video-stream></ui-video-stream>
        <ui-video-toolbar>
          <ui-video-tool icon="fa-phone fa-rotate-135" action="hangup"></video-tool>
        </ui-video-toolbar>
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
      @shadow.querySelector('ui-video-stream').display evt.stream, muted: false
    @peerConnection.onremovestream = (evt) =>
      @shadow.querySelector('ui-video-stream').display null, muted: true
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

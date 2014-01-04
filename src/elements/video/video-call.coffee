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
      #need to add these properties so they can be bound
      evt.stream.sourcemutedaudio = false
      evt.stream.sourcemutedvideo = false
      @shadow.querySelector('ui-video-stream').display evt.stream
    @peerConnection.onremovestream = (evt) =>
      @shadow.querySelector('ui-video-stream').display null
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
    #signal turned into a DOM event for this element, handling it here
    #to have a 'proper' rtc connection close and be nice to any TURN/STUN
    #along the path to the remote peer
    if message.hangup
      @peerConnection.close()
      @fire 'hangup',
        hangup: true
        callid: @getAttribute('callid')
        peerid: @getAttribute('peerid')
    #track the remote stream state here, too bad this isn't available
    #from the RTCPeerConnection media streams itself, but they only show
    #the stream state on 'this receiving side' and 'this sending side' not
    #'that sending side' piping us their video
    if message.sourcemutedaudio?
      console.log @shadow.querySelector('ui-video-stream').sourcemutedaudio = message.sourcemutedaudio

module.exports =
  VideoCall = VideoCall

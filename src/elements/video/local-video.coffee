Platform = require('polyfill-webcomponents')
getUserMedia = require('getusermedia')
attachMediaStream = require('attachmediastream')
webrtcSupport = require('webrtcsupport')
mixin = require('../mixin.coffee')
require = require('./video-tool-bar.coffee')

###
Video for yourself, this will get your local stream and show it.

#Events
selfvideostream: event.details.stream contains the local stream
###
class LocalVideo extends HTMLElement
  mediaConstraints:
    audio: true
    video:
      mandatory:
        maxWidth: 320
        maxHeight: 240
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
    <div class="tile video">
      <div>
        <video id="display"></video>
        <video-tool-bar>
          <video-tool icon="fa-video-camera" action="mutevideo"></video-tool>
          <video-tool icon="fa-microphone" action="muteaudio"></video-tool>
        </video-tool-bar>
      </div>
    </div>
    """
  enteredViewCallback: =>
    display = @shadow.querySelector('#display')
    getUserMedia @mediaConstraints, (err, stream) =>
      if err
        @fire 'error',
          stream: stream
          error: err
      else
        @fire 'localvideostream',
          stream: stream
        @stream = stream
        attachMediaStream stream, display, muted: true


module.exports =
  LocalVideo: document.register 'local-video', prototype: LocalVideo.prototype

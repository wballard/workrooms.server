Platform = require('polyfill-webcomponents')
getUserMedia = require('getusermedia')
attachMediaStream = require('attachmediastream')
webrtcSupport = require('webrtcsupport')
mixin = require('../mixin.coffee')
require('./video-tool-bar.coffee')
require('./ui-video-stream.coffee')

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
        <ui-video-stream></ui-video-stream>
        <video-tool-bar>
          <video-tool icon="fa-video-camera" action="mutevideo"></video-tool>
          <video-tool icon="fa-microphone" action="muteaudio"></video-tool>
        </video-tool-bar>
      </div>
    </div>
    """
  enteredViewCallback: =>
    @addEventListener 'stream', (evt) ->
        @fire 'localvideostream',
          stream: evt.detail.stream
    getUserMedia @mediaConstraints, (err, stream) =>
      if err
        @fire 'error',
          stream: stream
          error: err
      else
        @stream = stream
        @shadow.querySelector('ui-video-stream').display stream, muted: true

module.exports =
  LocalVideo: document.register 'local-video', prototype: LocalVideo.prototype

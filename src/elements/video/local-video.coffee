Platform = require('polyfill-webcomponents')
getUserMedia = require('getusermedia')
webrtcSupport = require('webrtcsupport')
mixin = require('../mixin.coffee')
require('./ui-video-toolbar.coffee')
require('./ui-video-stream.coffee')

###
Video for yourself, this will get your local stream and show it.

#Events
selfvideostream: event.details.stream contains the local stream
###
class LocalVideo extends HTMLElement
  mediaConstraints:
    audio: true
    video: true
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
    <div class="tile video">
      <div>
        <video-control>
          <audio-control>
            <ui-video-stream></ui-video-stream>
            <ui-video-toolbar>
              <ui-video-toggle icon="fa-video-camera" action="video" active="true"></ui-video-toggle>
              <ui-video-toggle icon="fa-microphone" action="audio" active="true"></ui-video-toggle>
            </ui-video-toolbar>
          </audio-control>
        </video-control>
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
        @shadow.querySelector('ui-video-stream').display stream,
          muted: true
          mirror: true

module.exports =
  LocalVideo: document.register 'local-video', prototype: LocalVideo.prototype

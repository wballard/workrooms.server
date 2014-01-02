Platform = require('polyfill-webcomponents')
mixin = require('../mixin.coffee')

###
This is essentially a macro to have semantic events and an icon across all
tools in the toolbar.
###
class VideoTool extends HTMLElement
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
      <a class="item">
        <i class="fa #{@getAttribute('icon')}"></i>
      </a>
    """
  enteredViewCallback: =>
    @on 'click', (evt) =>
      console.log 'click', @getAttribute('action')
      @fire @getAttribute('action')

###
Standard tools for video calls.
###
class VideoToolBar extends HTMLElement
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
    <div class="ui menu inverted">
      <video-tool icon="fa-phone" action="hangup"></video-tool>
      <video-tool icon="fa-video-camera" action="mutevideo"></video-tool>
      <video-tool icon="fa-microphone" action="muteaudio"></video-tool>
    </div>
    """
  enteredViewCallback: =>

module.exports =
  VideoToolBar: document.register 'video-tool-bar', prototype: VideoToolBar.prototype
  VideoTool: document.register 'video-tool', prototype: VideoTool.prototype

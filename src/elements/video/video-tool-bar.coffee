Platform = require('polyfill-webcomponents')
mixin = require('../mixin.coffee')

###
Standard tools for video calls.
###
class VideoToolBar extends HTMLElement
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
    <div class="ui menu inverted">
      <a class="item">
        <i class="fa fa-phone"></i>
      </a>
      <a class="item">
        <i class="fa fa-video-camera"></i>
      </a>
      <a class="item">
        <i class="fa fa-microphone"></i>
      </a>
    </div>
    """
  enteredViewCallback: =>

module.exports =
  VideoToolBar: document.register 'video-tool-bar', prototype: VideoToolBar.prototype

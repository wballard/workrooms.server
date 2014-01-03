platform = require('polyfill-webcomponents')
_ = require('lodash')
mixin = require('../mixin.coffee')

###
Displays a stream type video.

# Events
stream: bubbled up when the stream is changed, allows wrapping behaviors
  to know about the stream

# Methods
display(stream, options): shows a stream
  options:
    mute: this mutes the local stream audio output, different than muting the
      stream if it was being transported
###
class UIVideoStream extends HTMLElement
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
        <video></video>
    """
  display: (stream, options) ->
    options = _.extend
      muted: false
    , options
    @$('video', @shadow)
      .attr('src', URL.createObjectURL(stream) if stream)
      .attr('muted', options.muted)
      .attr('autoplay', true)
    @fire 'stream',
      stream: stream


module.exports =
  UIVideoStream: document.register 'ui-video-stream', prototype: UIVideoStream.prototype

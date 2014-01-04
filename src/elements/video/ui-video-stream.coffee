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
    mirror: reverse for local video
###
class UIVideoStream extends HTMLElement
  createdCallback: ->
    @shadow = @createShadowRoot()
    @shadow.innerHTML = """
      <span id="sourcemutedaudio" class="like ui corner label">
        <i class="icon fa fa-microphone-slash"></i>
      </span>
      <video></video>
    """
    @defineCustomElementProperty 'sourcemutedaudio'
  attributeChangedCallback: (name, oldValue, newValue) =>
    if name is 'sourcemutedaudio'
      if newValue is 'true'
        @$('#sourcemutedaudio', @shadow).show()
      else
        @$('#sourcemutedaudio', @shadow).hide()
  display: (stream, options) ->
    options = _.extend
      muted: false
    , options
    @$('video', @shadow)
      .attr('src', URL.createObjectURL(stream) if stream)
      .attr('autoplay', true)
    #this is local playback mute, not source mute
    if options.muted
      @$('video', @shadow)
        .attr('muted', '')
    else
      @$('video', @shadow)
        .removeAttr('muted')
    if options.mirror
      element = @$('video', @shadow)
        .css('-webkit-transform', 'scaleX(-1)')
    @fire 'stream',
      stream: stream

###
This one is a non-visual element.

This is a wrapper element that surrounds a `ui-video-stream`, listening for
the `stream` event, and implements mute/unmute.
###
class AudioControl extends HTMLElement
  createdCallback: ->
  enteredViewCallback: =>
    @addEventListener 'stream', (evt) =>
      @stream = evt.detail.stream
    @addEventListener 'audio.on', (evt) =>
      @stream?.getAudioTracks()?.forEach (x) -> x.enabled = true
    @addEventListener 'audio.off', (evt) =>
      @stream?.getAudioTracks()?.forEach (x) -> x.enabled = false

###
This one is a non-visual element. Well, sorta, it will change a wrapped
video, it just doesn't DOM itself.

This is a wrapper element that surrounds a `ui-video-stream`, listening for
the `stream` event, and implements mute/unmute.
###
class VideoControl extends HTMLElement
  createdCallback: ->
  enteredViewCallback: =>
    @addEventListener 'stream', (evt) =>
      @stream = evt.detail.stream
    @addEventListener 'video.on', (evt) =>
      @stream?.getVideoTracks()?.forEach (x) -> x.enabled = true
    @addEventListener 'video.off', (evt) =>
      @stream?.getVideoTracks()?.forEach (x) -> x.enabled = false


module.exports =
  UIVideoStream: document.register 'ui-video-stream', prototype: UIVideoStream.prototype
  AudioControl: document.register 'audio-control', prototype: AudioControl.prototype
  VideoControl: document.register 'video-control', prototype: VideoControl.prototype

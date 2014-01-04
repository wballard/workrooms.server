platform = require('polyfill-webcomponents')
_ = require('lodash')
mixin = require('../mixin.coffee')

SNAPSHOT_TIMEOUT = 30 * 1000

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
      <canvas></canvas>
      <img></img>
    """
    @defineCustomElementProperty 'sourcemutedaudio'
    @defineCustomElementProperty 'sourcemutedvideo'
  attributeChangedCallback: (name, oldValue, newValue) =>
    if name is 'sourcemutedaudio'
      if newValue is 'true'
        @$('#sourcemutedaudio', @shadow).show()
      else
        @$('#sourcemutedaudio', @shadow).hide()
    if name is 'sourcemutedvideo'
      if newValue is 'true'
        @$('video', @shadow).hide()
        @$('img', @shadow).show()
      else
        @$('video', @shadow).show()
        @$('img', @shadow).hide()
  display: (stream, options) ->
    options = _.extend
      muted: false
    , options
    video = @shadow.querySelector('video')
    width = parseInt(getComputedStyle(video).getPropertyValue('width').replace('px',''))
    height = 0
    streaming = false
    #components
    snapshot = @shadow.querySelector('canvas')
    takeSnapshot = ->
      ctx = snapshot.getContext('2d')
      ctx.drawImage(video, 0, 0, width, height)
      image.setAttribute('src', snapshot.toDataURL('image/png'))
    image = @shadow.querySelector('img')
    @$(image).hide()
    #this is local playback mute, not source mute
    if options.muted
      video.setAttribute('muted', '')
    else
      video.removeAttribute('muted')
    if options.mirror
      element = @$('video', @shadow)
        .css('-webkit-transform', 'scaleX(-1)')
    #size up when the video starts
    video.addEventListener 'canplay', ->
      if not streaming
        height = video.videoHeight / (video.videoWidth/width)
        video.setAttribute('width', width)
        video.setAttribute('height', height)
        snapshot.setAttribute('width', width)
        snapshot.setAttribute('height', height)
        streaming = true
        takeSnapshot()
        #good to go -- let everyone up the DOM know
        @fire 'stream',
          stream: stream
    #play that video
    video.src = URL.createObjectURL(stream)
    video.play()
    setInterval =>
      if not @hasAttribute('sourcemutedvideo') or @getAttribute('sourcemutedvideo') is 'false'
        takeSnapshot()
    , SNAPSHOT_TIMEOUT

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

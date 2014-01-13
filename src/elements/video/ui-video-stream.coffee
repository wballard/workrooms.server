platform = require('polyfill-webcomponents')
_ = require('lodash')
mixin = require('../mixin.coffee')


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
  AudioControl: document.register 'audio-control', prototype: AudioControl.prototype
  VideoControl: document.register 'video-control', prototype: VideoControl.prototype

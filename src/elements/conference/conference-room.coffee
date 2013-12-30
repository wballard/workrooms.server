###
Conference is an element that works a lot like a controller in other framerworks,
containting and coordinating other elements.

The basic idea here is to see if the entire notion of controllers can be tossed
if it is easy enough to just make a containing element.
###

Platform = require('polyfill-webcomponents')
bean = require('bean')
#other custom elements at least need to be loaded and registered
require('../video/local-video.coffee')
mixin = require('../mixin.coffee')

###
A ConferenceRoom brins together multiple video stream elements, giving you
a place to collaborate.
###
class ConferenceRoom extends HTMLElement
  createdCallback: ->
    mixin @
    @defineCustomElementProperty 'localVideo'
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = '<local-video> </local-video>'
  enteredViewCallback: =>
    bean.on @, 'localvideostream', (evt) =>
      console.log 'stream', evt, arguments
      @localVideo = evt.detail.stream

module.exports =
  ConferenceRoom: document.register 'conference-room', prototype: ConferenceRoom.prototype

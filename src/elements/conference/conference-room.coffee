###
Conference is an element that works a lot like a controller in other framerworks,
containting and coordinating other elements.

The basic idea here is to see if the entire notion of controllers can be tossed
if it is easy enough to just make a containing element.
###

Platform = require('polyfill-webcomponents')
bean = require('bean')
#other custom elements at least need to be loaded and registered
require('../video/video-avatar.coffee')

class ConferenceRoom extends HTMLElement
  createdCallback: ->
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = '<self-video-avatar> </self-video-avatar>'
  enteredViewCallback: =>
    bean.on @, 'selfvideostream', (evt) ->
      console.log 'stream', evt, arguments

module.exports =
  ConferenceRoom: document.register 'conference-room', prototype: ConferenceRoom.prototype

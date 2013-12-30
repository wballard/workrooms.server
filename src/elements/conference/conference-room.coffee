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
A `ConferenceRoom` brings together multiple video stream elements, giving you
a place to collaborate. The main benefit is that the conference room will deal
with `RTCPeerConnection` negotiation and signalling by talking to a web
socket based signalling server for you.
###
class ConferenceRoom extends HTMLElement
  createdCallback: ->
    mixin @
    @defineCustomElementProperty 'localVideo'
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = """
    <local-video></local-video>
    <outbound-video-call></outbound-video-call>
    """
  enteredViewCallback: =>
    console.log @.getAttribute 'server'
    bean.on @, 'localvideostream', (evt) =>
      console.log 'stream', evt, arguments
      @localVideo = evt.detail.stream

module.exports =
  ConferenceRoom: document.register 'conference-room', prototype: ConferenceRoom.prototype

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
require('../video/outbound-video-call.coffee')
require('../video/inbound-video-call.coffee')
mixin = require('../mixin.coffee')

###
A `ConferenceRoom` brings together multiple video stream elements, giving you
a place to collaborate. The main benefit is that the conference room will deal
with `RTCPeerConnection` negotiation and signalling by talking to a web
socket based signalling server for you.

#HTML Attributes
server: websocket url pointing to the signalling server
###
class ConferenceRoom extends HTMLElement
  createdCallback: ->
    mixin @
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = """
    <local-video></local-video>
    <outbound-video-call from="a" to="b"></outbound-video-call>
    <inbound-video-call from="a" to="b"></inbound-video-call>
    """
  enteredViewCallback: =>
    @socket = new WebSocket(@.getAttribute('server'))
    signalling = (message) =>
      @socket.send(JSON.stringify(message))
    @socket.onmessage = (evt) =>
      try
        #forward signal messages along to the video elements
        message = JSON.parse(evt.data)
        @shadow.querySelectorAll('inbound-video-call').forEach (inbound) =>
          inbound.signal signalling, message
        @shadow.querySelectorAll('outbound-video-call').forEach (outbound) =>
          outbound.signal signalling, message
      catch err
        @.fire 'error', error: err
    bean.on @, 'localvideostream', (evt) =>
      @shadow.querySelectorAll('outbound-video-call').forEach (outbound) =>
        outbound.call signalling, evt.detail.stream
      @shadow.querySelectorAll('inbound-video-call').forEach (inbound) =>
        inbound.listen signalling, evt.detail.stream

module.exports =
  ConferenceRoom: document.register 'conference-room', prototype: ConferenceRoom.prototype

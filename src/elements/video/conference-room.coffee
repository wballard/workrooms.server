###
Conference is an element that works a lot like a controller in other framerworks,
containting and coordinating other elements.

The basic idea here is to see if the entire notion of controllers can be tossed
if it is easy enough to just make a containing element.
###

Platform = require('polyfill-webcomponents')
#other custom elements at least need to be loaded and registered
require('./local-video.coffee')
require('./outbound-video-call.coffee')
require('./inbound-video-call.coffee')
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
    socket = new WebSocket(@getAttribute('server'))
    signalling = (message) =>
      socket.send(JSON.stringify(message))
    socket.onmessage = (evt) =>
      try
        #forward signal messages along to the video elements
        message = JSON.parse(evt.data)
        forMe = (call) ->
          message.to is call.getAttribute('to') and message.from is call.getAttribute('from')
        handleIce = (call) ->
          if message.ice and message.peerid isnt call.getAttribute('peerid')
            call.signal(message)
        handleOffer = (call) ->
          if message.offer
            call.signal(message)
        handleAnswer = (call) ->
          if message.answer
            call.signal(message)
        @shadow.querySelectorAll('inbound-video-call').forEach (call) ->
          if forMe(call)
            handleIce(call)
            handleOffer(call)
        @shadow.querySelectorAll('outbound-video-call').forEach (call) ->
          if forMe(call)
            handleIce(call)
            handleAnswer(call)
      catch err
        @fire 'error', error: err
    #all the webrtc process relies on their being a local video stream
    @on 'localvideostream', (evt) =>
      @shadow.querySelectorAll('outbound-video-call').forEach (outbound) =>
        outbound.call evt.detail.stream
        signalling
          register: true
          from: outbound.getAttribute('from')
          to: outbound.getAttribute('to')
      @shadow.querySelectorAll('inbound-video-call').forEach (inbound) =>
        inbound.listen evt.detail.stream
        signalling
          register: true
          from: inbound.getAttribute('from')
          to: inbound.getAttribute('to')
    @on 'ice', (evt) =>
      signalling evt.detail
    @on 'sdp', (evt) =>
      signalling evt.detail

module.exports =
  ConferenceRoom: document.register 'conference-room', prototype: ConferenceRoom.prototype

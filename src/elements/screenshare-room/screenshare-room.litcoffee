Screenshare 'room' fills up the entire tab with screen sharing.

    SignallingServer = require '../../scripts/signalling-server.litcoffee'
    _ = require 'lodash'

    Polymer 'screenshare-room',

#Attributes
##screenLink
The screen is an encoded `client/screen` pair. When it changes, go to the 
server to signal inbound and outbound call pairs.

      screenLinkChanged: ->
        @signallingServer.send 'callscreen',
          fromclientid: @screenLink.split('/')[0].slice(1)
          toclientid: @signallingServer.clientid
          screenid: @screenLink.split('/')[1]

#Polymer Lifecycle
Main thing going on here it setting up signalling service, which isn't an
element, it is just code.

      attached: ->
        @root = "#{document.location.origin}#{document.location.pathname}"
        if @root.slice(0,3) isnt 'https'
          window.location = "https#{@root.slice(4)}#{document.location.hash or ''}"
        if @root.slice(-1) isnt '/'
          @root += '/'

##Setting Up Signalling
Hello from the server! Now it is time to register this client in order to
get the rest of the configuration.

        @signallingServer = new SignallingServer("ws#{@root.slice(4)}")

        @signallingServer.on 'error', (err) ->
          console.log err

Register without a room. This allows RTC signalling to flow.

        @signallingServer.on 'hello', =>
          @fire 'hello'
          @signallingServer.send 'register',

This view has only the one screen, it is a full screen tab.

        @signallingServer.on 'inboundscreen', (screen) =>
          @screen = screen

##Call Signal Processing
Relay signalling server messages into the calls.

        @addEventListener 'ice', (evt) =>
          evt.detail.nolog = true
          @signallingServer.send 'ice', evt.detail
        @signallingServer.on 'ice', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processIce detail

        @addEventListener 'offer', (evt) =>
          @signallingServer.send 'offer', evt.detail
        @signallingServer.on 'offer', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processOffer detail

        @addEventListener 'answer', (evt) =>
          @signallingServer.send 'answer', evt.detail
        @signallingServer.on 'answer', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processAnswer detail

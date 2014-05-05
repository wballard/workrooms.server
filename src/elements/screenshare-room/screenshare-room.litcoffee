Screenshare 'room' fills up the entire tab with screen sharing.

    SignallingServer = require '../../scripts/signalling-server.litcoffee'

    Polymer 'screenshare-room',

#Attributes
##screen
The screen is an encoded `client/screen` pair.

      screenChanged: ->
        console.log @screen
        @signallingServer.send 'callscreen',
          fromclientid: @screen.split('/')[0].slice(1)
          toclientid: @signallingServer.clientid
          screenid: @screen.split('/')[1]

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

        @signallingServer.on 'hello', =>
          @fire 'hello'

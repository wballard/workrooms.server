#Overview
This event sink takes DOM events and relays them along to a websocket
server. Incoming websocket messages are translated into DOM events
to bubble up the DOM so they can be handled by all kinds of elements.

#Attributes
##events
This is a space separated list of event names that will be relayed to the
server.
##server
This is a `ws://` or `wss:///` url pointing to your websocket server.

#Events
##error
Fires off when trouble happens.
##connect
Fires when the initial connection has been made.
##reconnect
Fires when the server connection has been interrupted and then restored.
##*
This is a bit of a wildcard emitter, any websocket message received is
turned into a DOM event with `.type` being the event name and `.detail` passed
as the custom event detail.

    ReconnectingWebSocket = require('./reconnecting-websocket.litcoffee')
    uuid = require('node-uuid')
    TIMEOUT = 1000

    Polymer 'websocket-event-sink',
      sessionid: uuid.v1()
      attached: ->
        console.log 'attach websocket', @events
        setInterval =>
          try
            @socket?.send JSON.stringify(
              ping: true
              from: @sessionid
            )
          catch err
            console.log err
        , TIMEOUT
      detached: ->
        @socket?.close()

Relay events along to the websocket, giving the signalling server the chance
to share messages with other clients. But, really important to not relay
messages you posted, otherwise it's essentially an infinite loop.

      relay: (evt) ->
        if evt.target isnt @
          console.log 'websocket relay', evt.detail
          @socket?.send JSON.stringify(
            type: evt.type
            detail: evt.detail
            from: @sessionid
          )

Keep a strict subscription to only the events specified by attribute.

      eventsChanged: (oldValue, newValue) ->
        (oldValue or '').split(' ').forEach (name) =>
          @removeEventListener name.trim(), @relay
        (newValue or '').split(' ').forEach (name) =>
          @addEventListener name.trim(), @relay

Set up the socket when the server attribute is supplied. This turns webwocket
messages into DOM events, which bubble.

      serverChanged: (oldValue, newValue) ->
        @socket?.close()
        if newValue
          @socket = new ReconnectingWebSocket(newValue)
          @socket.onreconnect = =>
            @fire 'reconnect'
          @socket.onconnect = =>
            @fire 'connect'
          @socket.onmessage = (evt) =>
            try
              message = JSON.parse(evt.data)
              if message.type
                @fire message.type, message.detail
            catch err
              @fire 'error', err

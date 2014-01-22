#Overview
This event sink takes DOM events and relays them along to a websocket
server. Incoming websocket messages are translated into DOM events
to bubble up the DOM so they can be handled by all kinds of elements.

So, this is like an `event-sink`, but it is the out of process approach that
lets multiple different users in different browsers collaborate via events.
Use an `event-sink` to wrap around DOM elements and relay events
back to `event-source` elements. This lets you bubble events 'up' the
DOM and have them restart down deep in the DOM again.

#Attributes
##events
This is a space separated list of event names that will be relayed to the
server.
##server
This is a `ws://` or `wss:///` url pointing to your websocket server.

#Events
##error
Fires off when trouble happens.
##*
This is a bit of a wildcard emitter, any websocket message received is
turned into a DOM event with `.type` being the event name and `.detail` passed
as the custom event detail.

    ReconnectingWebSocket = require('./reconnecting-websocket.litcoffee')
    uuid = require('node-uuid')

    Polymer 'websocket-event-sink',
      sesionid: uuid.v1()
      sources: []
      attached: ->
      detached: ->
        @socket?.close()

Relay events. The most important rule here is to not relay events that
themselves were relayed already, which can be detected by looking if they
came from an `event-source`.

      relay: (evt) ->
        if evt?.srcElement?.nodeName isnt "EVENT-SOURCE"
          @socket?.send JSON.stringify(
            type: evt.type
            detail: evt.detail
            from: @sesionid
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
          @socket.onmessage = (evt) =>
            try
              message = JSON.parse(evt.data)
              if message.type
                @fire message.type, message.detail
            catch err
              console.log err
              @fire 'error', err

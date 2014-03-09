#Overview
This event sink takes DOM events and relays them along to a websocket
server. Incoming websocket messages are translated into structured dom
events with a `name` and `detail` to emit much like DOM events.

#Events
##error
Fires off when trouble happens.
##*
This is a bit of a wildcard emitter, any websocket message received is
turned into a DOM event with `.type` being the event name and `.detail` passed
as the custom event detail.

    HuntingWebsocket = require('./hunting-websocket.litcoffee')
    EventEmitter = require('events').EventEmitter
    uuid = require('node-uuid')

    module.exports =
      class SignallingServer extends EventEmitter
        sessionid: uuid.v1()
        constructor: (@config) ->
          @socket = new HuntingWebsocket([@config.signallingServer])
          @socket.onerror = (err) =>
            @emit 'error', err
          @socket.onmessage = (evt) =>
            try
              message = JSON.parse(evt.data)
              if message.type
                @emit message.type, message.detail
            catch err
              @emit 'error', err
        send: (name, detail)->
            @socket?.send JSON.stringify(
              type: name
              detail: detail
              from: @sessionid
            )

Pipe a `name` message from `this` to `target`.

        pipe: (name, target) ->
          @on name, (detail) ->
            target.send name, detail


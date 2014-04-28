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
    KEEPALIVE_TIMEOUT = 5 * 1000

    module.exports =
      class SignallingServer extends EventEmitter
        clientid: uuid.v1()
        constructor: (@url) ->
          console.log 'clientid', @clientid
          @socket = new HuntingWebsocket([@url])
          @socket.onerror = (err) =>
            @emit 'error', err
          @socket.onmessage = (evt) =>
            try
              message = JSON.parse(evt.data)
              if message.type
                unless message.detail.nolog
                  console.log('<--', message.type, message.detail)
                @emit message.type, message.detail
            catch err
              @emit 'error', err
          setInterval =>
            @send 'ping', nolog: true
          , KEEPALIVE_TIMEOUT

All done now.

        close: ->
          @socket.close()

Send and event structured `type` and `detail` message along to the
server.

        send: (type, detail) ->
          unless detail.nolog
            console.log('-->', type, detail)
          @socket?.send JSON.stringify(
            type: type
            detail: detail
            clientid: @clientid
          )

Pipe a `name` message from `this` to `target`.

        pipe: (name, target) ->
          @on name, (detail) ->
            console.log 'piping', name, target
            target.send name, detail


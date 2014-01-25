The basic idea here is that WebSockets can get interrupted when going to talk
to their server. So, this WebSocket takes a small inspiration from
[0MQ](http://zeromq.org/) and combines:

* a buffer queue of outbound messages
* automatic reconnection

This has the exact same API as
[WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket). So
you get going with:

```
ReconnectingWebSocket = require(reconnecting-websocket)
ws = new ReconnectingWebSocket('ws://...');
```

Oh -- and this is a *client side* WebSocket, and is set up to work
with [Browserify](http://browserify.org/). Client side matters since it initiates
the WebSocket connection, so is the only side in a place to reconnect.

If you explicitly call `close()`, then this socket will really close, otherwise
it will work to automatically reconnect `onerror` and `onclose` from the
underlying WebSocket.

#Events
##onreconnect(event)
This callback is fired when the socket reconnects. This is separated from the
`onconnect(event)` callback so that you can have different behavior on the
first time connection from subsequent connections.
##onsend(event)
Fired after a message has gone out the socket.
##ws
A reference to the contained WebSocket in case you need to poke under the hood.

    class ReconnectingWebSocket
      constructor: (@url, @protocols) ->
        @messages = []
        @ws = new WebSocket(@url, @protocols)
        @forceclose = false
        @readyState = WebSocket.CONNECTING
        @connectionCount = 0

The all powerful connect function, sets up events and error handling.

      connect: (timeout) =>
        @ws = new WebSocket(@url, @protocols)
        @ws.onopen = (event) =>
          @readyState = WebSocket.OPEN
          if @connectionCount++
            @onreconnect(event)
          else
            @onopen(event)
          @drain()
        @ws.onclose = (event) =>
          if @forceclose
            @readyState = WebSocket.CLOSED
            @onclose(event)
          else
            @readyState = WebSocket.CONNECTING
        @ws.onmessage = (event) =>
          @onmessage(event)
        @ws.onerror = (event) =>
          console.log 'socket error', event
          @onerror(event)

      send: (data) =>
        @messages.push(data)
        @drain()

      close: =>
        @forceclose = true
        @ws.close()

Drain out the pending messages, but only consume them if a send
was without error. Bail out if we do error, as it is now time to
reconnect and let a fresh connection try the message.

This will connect if not connected, which then comes back to drain -- finishing
the process.

      drain: =>
        if @readyState is WebSocket.OPEN
          while @messages.length
            try
              @ws.send @messages[0]
              sent = @messages.shift()
              @onsend(new MessageEvent(sent))
            catch err
              console.log err
              return
        else
          @connect()

Empty shims for the event handlers. These are just here for discovery via
the debugger.

      onopen: (event) ->
      onclose: (event) ->
      onreconnect: (event) ->
      onmessage: (event) ->
      onerror: (event) ->
      onsend: (event) ->

Publish this object for browserify.

      module.exports = ReconnectingWebSocket

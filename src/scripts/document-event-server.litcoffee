This is a simple `EventEmitter` bridge with a notion of named channels.

    EventEmitter = require('events').EventEmitter
    module.exports =
      class DocumentEventServer extends EventEmitter
        constructor: (@channel) ->
          document.addEventListener 'document-event-server', (evt) =>
            message = evt.detail
            if message.channel is @channel
              @emit message.type, message.detail

Send a `name` message with object `detail` over chrome messaging on this
channel.

        send: (name, detail, toAllTabs) ->
          @emit name, detail
          evt = new CustomEvent 'document-event-server', 
            detail:
              channel: @channel
              type: name
              detail: detail
          document.dispatchEvent evt

Pipe a `name` message from `this` to `target`.

        pipe: (name, target) ->
          @on name, (detail) ->
            target.send name, detail

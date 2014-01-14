Calls between users require coordinating between the call itself,
which is a request, and the call tab. This call queue is that messaging
junction point.

Call requests come in from click-to-dial elements on other web pages, like
Github. Need to get those up and over into this extension, so -- messages.

The idea is that you queue up call requests so that when the conference
tab becomes available, you get all the pending calls and set them up. This
is driven by needing the `RTCPeerConnection` in the tab page so you can
get a reference to it and hook into the media streams.

    _ = require('lodash')

    Polymer 'call-queue',
      callQueue: []
      attached: ->
        chrome.runtime.onMessage.addListener (message, sender, respond) =>
          console.log 'background', message
          if message.call
            cleaned = _.clone(message)
            @callQueue.push(cleaned)
            chrome.runtime.sendMessage
              showConferenceTab: true
          if message.dequeueCalls
            calls = @callQueue
            @callQueue = []
            chrome.runtime.sendMessage
              makeCalls: calls

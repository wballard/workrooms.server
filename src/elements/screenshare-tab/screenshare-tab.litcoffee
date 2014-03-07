Background element to create screenshare tabs as needed. This will respond
to `inboundscreen` and `outboundscreen` messages, setting up a tab that
will do a peer to peer.

* TODO: code-line this with Chrome 34

    Polymer 'screenshare-tab',
      tabToCall: {}
      showCallTab: (call) ->
          tabURL = chrome.runtime.getURL('/tabs/screenshare.html') + "?#{call.id}"
          remember = (tab) =>
            console.log 'created', tab, call
            @tabToCall[tab.id] = call
          chrome.tabs.query url: tabURL, (tabs) ->
            if tabs.length
              tabs.forEach remember
            else
              chrome.tabs.create
                url: "tabs/screenshare.html?#{call.id}"
                index: 1
              , remember


      attached: ->

        chrome.tabs.onRemoved.addListener (tabid) =>
          @fire 'hangupscreenshare', @tabToCall[tabid]
          delete @tabToCall[tabid]

        @addEventListener 'inboundscreen', (evt) =>
          @showCallTab evt.detail

        @addEventListener 'outboundscreen', (evt) =>
          @showCallTab evt.detail

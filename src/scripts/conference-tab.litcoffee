Control the conference tab. This makes a new tab using the Chrome
extension API, but also adds a couple features:

* restores tab state, useful especially with `chrome-devreloader`
* makes the tab a singleton
* provides an event 'pipe' to send messages from the background
  page and websockets along to the tab

    EventEmitter = require('events').EventEmitter

    module.exports = 
      class ConferenceTab extends EventEmitter

And restore from local storage...

        constructor: ->
          chrome.storage.local.get 'conference', (config) =>
            @show() if config.conference

Showing sets local storage memory and fires off `conferencetabvisible`.

        show: ->
          conferenceURL = chrome.runtime.getURL('/tabs/conference.html')
          remember = (tab) =>
            chrome.tabs.update tab.id, active: true
            chrome.storage.local.set conference: true
            @visible = true
            @emit 'conferencetabvisible'
            chrome.tabs.onRemoved.addListener (id) =>
              if id is tab.id
                chrome.storage.local.set conference: false
                @visible = false
          chrome.tabs.query url: conferenceURL, (tabs) ->
            if tabs.length
              tabs.forEach remember
            else
              chrome.tabs.create
                url: 'tabs/conference.html'
                index: 0
              , remember



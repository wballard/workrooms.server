Control the conference tab. This makes a new tab using the Chrome
extension API, but also adds a couple features:

* restores tab state, useful especially with `chrome-devreloader`
* makes the tab a singleton

#Attributes
##visible
If present, indicates that the tab is being show.
#Events
##conferencetabvisible
Fired when the tab is show

    Polymer 'conference-tab',

Using messages to trigger the tab show. These are extension messages
rather than DOM events since we will be going between the extension and
tabs with content triggering a click-to-dial.

      attached: ->
        @addEventListener 'showconferencetab', ->
          conferenceURL = chrome.runtime.getURL('/tabs/conference.html')
          remember = (tab) =>
            chrome.tabs.update tab.id, active: true
            chrome.storage.local.set conference: true
            @setAttribute 'visible', ''
            @fire 'conferencetabvisible'
            chrome.tabs.onRemoved.addListener (id) =>
              if id is tab.id
                chrome.storage.local.set conference: false
                @removeAttribute 'visible'
          chrome.tabs.query url: conferenceURL, (tabs) ->
            if tabs.length
              tabs.forEach remember
            else
              chrome.tabs.create
                url: 'tabs/conference.html'
                index: 0
              , remember


And restore from local storage...

        chrome.storage.local.get 'conference', (config) =>
          if config.conference
            @fire 'showconferencetab'

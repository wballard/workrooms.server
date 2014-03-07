This sets up a content script to watch for tabs
that have *gravatar* images using Chrome content script APIs.

    EventEmitter = require('events').EventEmitter
    module.exports =
      class GravatarDetector extends EventEmitter
        constructor: ->
          chrome.tabs.query {}, (tabs) =>
            tabs.forEach @inject
          chrome.tabs.onUpdated.addListener (tabid, change, tab) =>
            if change.status is 'complete'
              @inject tab

Inject into an individual tab. Nothing fancy here except pay
attention to the paths of the files.

        inject: (tab) ->
          console.log 'injecting', tab
          ret = chrome.tabs.executeScript tab.id,
            file: '/scripts/gravatar-contentscript.js'
            allFrames: true
          chrome.tabs.insertCSS tab.id,
            file: '/scripts/gravatar-contentscript.css'
            allFrames: true

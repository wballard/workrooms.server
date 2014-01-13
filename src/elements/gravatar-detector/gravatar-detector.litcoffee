This element sets up a content script to watch for tabs
that have *gravatar* images using Chrome content script APIs.

The idea is you put this in your background page to enable the feature,
this isn't really a visible DOM element itself.


    Polymer 'gravatar-detector',
      ready: ->
        chrome.tabs.query {}, (tabs) ->
          tabs.forEach inject
        chrome.tabs.onUpdated.addListener (tabid, change, tab) ->
          if change.status is 'complete'
            inject tab

Inject into an individual tab. Nothing fancy here except pay
attention to the paths of the files.

    inject = (tab) ->
      console.log 'injecting into', tab
      ret = chrome.tabs.executeScript tab.id,
        file: '/bower_components/gravatar-detector/contentscript.js'
        allFrames: true
      chrome.tabs.insertCSS tab.id,
        file: '/bower_components/gravatar-detector/gravatars.css'
        allFrames: true

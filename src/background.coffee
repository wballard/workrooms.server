###
Basic idea here is to have exactly one entry point, built up by browserify, but
that can tell when code changes and will hot reload.
###

ajax = require('component-ajax')
require('./elements/extension-icon.coffee')
require('./elements/github-oauth.coffee')
require('./less/main.less')

###
Check all the referenced background scripts, and see if they have changed. This
uses local storage to 'diff' the code of the background scripts, and on
a difference, reloads.
###
reloadIfChanged = ->
  for script in chrome.runtime.getManifest()?.web_accessible_resources
    do ->
      codeURL = chrome.runtime.getURL(script)
      ajax.get codeURL, (code) ->
        chrome.storage.local.get codeURL, (storedCode) ->
          if storedCode[codeURL] isnt code
            console.log "new code! let's reload"
            reload = true
          else
            reload = false
          save = {}
          save[codeURL] = code
          chrome.storage.local.set save, ->
            chrome.runtime.reload() if reload
  setTimeout reloadIfChanged, 1000
reloadIfChanged()

###
Restore the state of the conference tab after a hotload.
###
showConferenceTab = ->
  conferenceURL = chrome.runtime.getURL('build/tabs/conference.html')
  remember = (tab) ->
    chrome.tabs.update tab.id, active: true
    chrome.storage.local.set conference: true
    chrome.tabs.onRemoved.addListener (id) ->
      chrome.storage.local.set conference: false

  chrome.tabs.query url: conferenceURL, (tabs) ->
    if tabs.length
      tabs.forEach remember
    else
      chrome.tabs.create
        url: 'build/tabs/conference.html'
        index: 0
      , remember

#of course, chrome events don't follow the pattern for dom elements
chrome.browserAction.onClicked.addListener ->
  showConferenceTab()

chrome.storage.local.get 'conference', (conference) ->
  if conference.conference
    showConferenceTab()

###
Hook up every tab to content injection and monitoring.
###
chrome.tabs.query {}, (tabs) ->
  tabs.forEach (tab) ->
    chrome.tabs.executeScript tab.id,
      file: './build/gravatars.js'
      allFrames: true
    chrome.tabs.insertCSS tab.id,
      file: './build/gravatars.css'
      allFrames: true

console.log 'a'

###
Basic idea here is to have exactly one entry point, built up by browserify, but
that can tell when code changes and will hot reload.
###

require('./elements/extension-icon.coffee')
require('./elements/github-oauth.coffee')
require('./elements/mixin.coffee')
config = require('./config.yaml')?[chrome.runtime.id]

###
Check all the referenced background scripts, and see if they have changed. This
uses local storage to 'diff' the code of the background scripts, and on
a difference, reloads.
###

###
Restore the state of the conference tab after a hotload.
###
showConferenceTab = ->
  conferenceURL = chrome.runtime.getURL('tabs/conference.html')
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
        url: 'tabs/conference.html'
        index: 0
      , remember

#of course, chrome events don't follow the pattern for dom elements
chrome.browserAction.onClicked.addListener ->
  showConferenceTab()

chrome.storage.local.get 'conference', (conference) ->
  if conference.conference
    showConferenceTab()

###
Messages from content injection do the call start. This will launch
the call tab, which is asynchronous for sure. So, queue up a call request
such that the conference tab can get a chance to consume it
###
callQueue = []
chrome.runtime.onMessage.addListener (message, sender, respond) ->
  console.log 'background', message
  if message.call
    callQueue.push(message)
    showConferenceTab()
  if message.dequeueCalls and callQueue.length
    calls = callQueue
    callQueue = []
    chrome.runtime.sendMessage
      makeCalls: calls
  if message.showConference
    showConferenceTab()


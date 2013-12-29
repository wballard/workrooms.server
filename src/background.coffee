###
Basic idea here is to have exactly one entry point, built up by browserify, but
that can tell when code changes and will hot reload.
###

ajax = require('component-ajax')
bean = require('bean')
ExtensionIcon = require('./script/extension-icon.coffee')
require('./less/main.less')

###
Check all the referenced background scripts, and see if they have changed. This
uses local storage to 'diff' the code of the background scripts, and on
a difference, reloads.
###
reloadIfChanged = ->
  for script in chrome.runtime.getManifest()?.background?.scripts
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

poll = ->
  setTimeout ->
    reloadIfChanged()
    poll()
  , 1000

poll()

icon = new ExtensionIcon()
bean.on icon, 'change', ->
  console.log 'changed'
document.body.appendChild icon

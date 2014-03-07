This is a fun one -- keep an eye on `web_accessible_resources`
and if there is a change, trigger a chrome extension reload.

#Attributes
##config
Object with settings, this is going to look for a property
`reload`.

    ajax = require('component-ajax')
    md5 = require('MD5')

    module.exports = (config) ->
      if config.reload
        console.log 'autoreloading!'
        reloadIfChanged = ->
          for script in chrome.runtime.getManifest()?.web_accessible_resources
            do ->
              codeURL = chrome.runtime.getURL(script)
              ajax.get codeURL, (code) ->
                hash = md5(code)
                chrome.storage.local.get codeURL, (storedCode) ->
                  if storedCode[codeURL] isnt hash
                    console.log "new code! let's reload"
                    reload = true
                  else
                    reload = false
                  save = {}
                  save[codeURL] = hash
                  chrome.storage.local.set save, ->
                    setTimeout ->
                      chrome.runtime.reload() if reload
                    , 2000
          setTimeout reloadIfChanged, 1000
        reloadIfChanged()

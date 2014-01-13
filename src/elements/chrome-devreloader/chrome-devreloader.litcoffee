This is a fun one -- keep an eye on `web_accessible_resources`
and if there is a change, trigger a chrome extension reload.

#Attributes
##config
Object with settings, this is going to look for a property
`reload`.

    ajax = require('component-ajax')

    Polymer 'chrome-devreloader',

Starting up when attached so we are sure to have `config` bound. The main idea
here is to just load up all the files with a local access then compare them
to the last known version stashed in local storage. On any diff, reload!

      attached: ->
        if @config.reload
          console.log 'autoreloading!'
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

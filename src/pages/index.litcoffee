Main page script. Not particularly interesting as everything is an element.

    require '../elements/elementmixin.litcoffee'
    domready = require 'domready'

    version = undefined

    domready ->
      document.querySelector('conference-room').hide()

    document.addEventListener 'hello', ->
      document.querySelector('#loading').hideAnimated()
      document.querySelector('conference-room').room = window.location.hash
      document.querySelector('conference-room').showAnimated()

    document.addEventListener 'pong', (evt) ->
      if version and evt?.detail?['all'] isnt version
        window.location.reload()
      else
        version = evt.detail['all']
        console.log 'version', version

    window.addEventListener 'hashchange', ->
      document.querySelector('conference-room').room = window.location.hash

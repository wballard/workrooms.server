Main page script. Not particularly interesting as everything is an element.

    require '../elements/elementmixin.litcoffee'
    domready = require 'domready'

    version = undefined

    domready ->
      document.querySelector('conference-room').hide()

    document.addEventListener 'hello', ->
      document.querySelector('#loading').hide ->
        document.querySelector('conference-room').room = window.location.hash
        document.querySelector('conference-room').show()

    document.addEventListener 'pong', (evt) ->
      if version and evt?.detail?['index.html'] isnt version
        window.location.reload()
      else
        version = evt.detail['index.html']

    window.addEventListener 'hashchange', ->
      document.querySelector('conference-room').room = window.location.hash

    window.addEventListener 'focus', ->
      document.querySelector('conference-room').focused = true

    window.addEventListener 'blur', ->
      document.querySelector('conference-room').focused = false

Main page script. Not particularly interesting as everything is an element.

    require '../elements/elementmixin.litcoffee'
    domready = require 'domready'

    domready ->
      document.querySelector('screenshare-room').hide()

    document.addEventListener 'hello', ->
      document.querySelector('#loading').hideAnimated()
      document.querySelector('screenshare-room').screen =
        window.location.hash
      document.querySelector('screenshare-room').showAnimated()

    window.addEventListener 'hashchange', ->
      document.querySelector('screenshare-room').screen =
        window.location.hash

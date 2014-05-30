Main page script. Not particularly interesting as everything is an element.

    require './elementmixin.litcoffee'
    domready = require 'domready'

    domready ->
      document.querySelector('screenshare-room').hide()

    document.addEventListener 'hello', ->
      document.querySelector('#loading').hide()
      document.querySelector('screenshare-room').screenLink =
        window.location.hash
      document.querySelector('screenshare-room').show()

    window.addEventListener 'hashchange', ->
      document.querySelector('screenshare-room').screenLink =
        window.location.hash

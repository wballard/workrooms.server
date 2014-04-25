Main page script. Not particularly interesting as everything is an element.

    require '../elements/elementmixin.litcoffee'

    document.addEventListener 'hello', ->
      document.querySelector('#loading').hideAnimated()
      document.querySelector('conference-room').room = window.location.hash

    window.addEventListener 'hashchange', ->
      document.querySelector('conference-room').room = window.location.hash


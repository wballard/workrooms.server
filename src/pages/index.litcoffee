Main page script. Not particularly interesting as everything is an element.

    require '../elements/elementmixin.litcoffee'

    document.addEventListener 'ready', ->
      document.querySelector('#loading').hideAnimated()


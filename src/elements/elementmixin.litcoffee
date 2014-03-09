Mixin methods to HTMLElement.

    bonzo = require('bonzo')
    bean = require('bean')
    morpheus = require('morpheus')

Showing with animation and a callback that fires once it is done.

    if not HTMLElement::showAnimated
      HTMLElement::showAnimated = (callback) ->
        bonzo(@).show().attr 'style', 'opacity: 0;'
        morpheus @,
          opacity: 1.0
          complete: ->
            callback() if callback

Hiding with animation and a callback that fires once it is done.

    if not HTMLElement::hideAnimated
      HTMLElement::hideAnimated = (callback) ->
        morpheus @,
          width: 0
          opacity: 0
          complete: ->
            bonzo(@).hide()
            callback() if callback

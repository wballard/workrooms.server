Mixin methods to HTMLElement.

    bonzo = require('bonzo')
    bean = require('bean')
    morpheus = require('morpheus')

Showing with animation and a callback that fires once it is done.

    if not HTMLElement::showAnimated
      HTMLElement::showAnimated = (callback) ->
        bonzo(@).show()
        @visible = true
        callback() if callback

Hiding with animation and a callback that fires once it is done.

    if not HTMLElement::hideAnimated
      HTMLElement::hideAnimated = (callback) ->
        bonzo(@).hide()
        @visible = false
        callback() if callback

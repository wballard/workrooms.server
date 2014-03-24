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

jQuery doesn't seem to understand offset and position with polymer.

    $.fn.position = ->
      if not @[0]
        return
      else
        bonzo(@[0]).offset()

Tooltip positioning.

    if not HTMLElement::tooltipPosition
      HTMLElement::tooltipPosition = ->
        if bonzo(@).offset().left > (bonzo(@).parent().offset().width/2)
          'bottom left'
        else
          'bottom right'


Mixin methods to HTMLElement.

    bonzo = require('bonzo')
    bean = require('bean')
    _ = require('lodash')

    ANIMATION_DURATION = 300

Showing with animation and a callback that fires once it is done.

    if not HTMLElement::show
      HTMLElement::show = (callback) ->
        @visible = true
        @classList.remove('hide')
        callback() if callback

Hiding with animation and a callback that fires once it is done.

    if not HTMLElement::hide
      HTMLElement::hide = (callback) ->
        @visible = false
        @classList.add('hide')
        callback() if callback

jQuery doesn't seem to understand offset and position with polymer. This patch
makes the semantic-ui tooltips show in the right spot.

    if jQuery?
      jQuery.fn.position = ->
        if not @[0]
          return
        else
          bonzo(@[0]).offset()

Turn all the keys into a string.

    if PolymerExpressions?
      PolymerExpressions::keyString = (obj) ->
        _.keys(obj).join(' ')

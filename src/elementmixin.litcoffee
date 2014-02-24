Mixin methods to HTMLElement.

    bonzo = require('bonzo')
    bean = require('bean')

Showing with animation and a callback that fires once it is done.

    if not HTMLElement::showAnimated
      HTMLElement::showAnimated = (callback) ->
        console.log 'show', @
        bean.one @, 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', =>
          callback() if callback
        bonzo(@)
          .show()
          .addClass('animated')
          .addClass('fadeInDown')
          .removeClass('fadeOutDown')

Hiding with animation and a callback that fires once it is done.

    if not HTMLElement::hideAnimated
      HTMLElement::hideAnimated = (callback) ->
        console.log 'hide', @
        bean.one @, 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', =>
          bonzo(@).hide()
          callback() if callback
        bonzo(@)
          .addClass('animated')
          .addClass('fadeOutDown')
          .removeClass('fadeInDown')

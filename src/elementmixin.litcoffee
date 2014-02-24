Mixin methods to HTMLElement.

    bonzo = require('bonzo')
    bean = require('bean')

Showing with animation and a callback that fires once it is done.

    if not HTMLElement::showAnimated
      HTMLElement::showAnimated = (callback) ->
        bean.one @, 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', callback
        bonzo(@)
          .addClass('animated')
          .addClass('fadeInDown')
          .removeClass('fadeOutDown')
          .show()

Hiding with animation and a callback that fires once it is done.

    if not HTMLElement::hideAnimated
      HTMLElement::hideAnimated = (callback) ->
        bean.one @, 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', callback
        bonzo(@)
          .addClass('animated')
          .addClass('fadeOutDown')
          .removeClass('fadeInDown')

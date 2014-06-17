Mixin methods to HTMLElement.

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


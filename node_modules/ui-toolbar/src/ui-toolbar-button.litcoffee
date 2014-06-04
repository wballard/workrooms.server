#ui-toolbar-button
A simple, [FontAwesome](http://fortawesome.github.io/Font-Awesome/) based
tool button. This supports:

* active state toggling
* hotkey mapping
* clicking

Check out [demo.html](demo.html) to see a sample.

    Polymer 'ui-toolbar-button',

##Events
###click
Good old click, handle this to do the deed. This will also be fired when
the `hotkey` is pressed.

##Attributes and Change Handlers
###active
Toggle state for the button, `true` is on.
###enabled
Enable or disable the button.
###toggle
Automatically enable or disable on `click`.
###icon
This is a `fa-` icon name.
###hotkey
Character or character code to enable hotkeys. For example 32 is hotkey space.
###selected
You can use a tool icon as a menu item, when it is `selected` it stands out.

      selectedChanged: ->
        if @selected
          @$.selector.classList.add 'selected'
        else
          @$.selector.classList.remove 'selected'

##Methods

##Event Handlers
Mouse and action handling is via PointerEvents. These are used to trigger
the animation styles.

      pointerdown: ->
        if @enabled
          @$.tool.classList.add 'pressed'
      pointerup: ->
        @$.tool.classList.remove 'pressed'
      click: (evt) ->
        if not @enabled
          evt.preventDefault()
          evt.stopPropagation()
          return false
      pointerenter: ->
      pointerleave: ->
      pointerclick: (evt) ->
        if @toggle
          @active = not @active

##Polymer Lifecycle

      created: ->
        @toggle = false
        @active = true
        @enabled = true

      ready: ->

      attached: ->

This element hooks to the document to process hotkeys.

        document.addEventListener 'keydown', (e) =>
          return unless @hotkey
          key = if isNaN(@hotkey) then String.fromCharCode(e.keyCode).toLowerCase() else e.keyCode.toString()
          activeElem = document.activeElement.tagName.toLowerCase()
          if @enabled and key is @hotkey and ( e.altKey or ( activeElem != 'textarea' and activeElem != 'input' ) )
            @fire 'click'
            e.preventDefault?()
            e.stopPropagation?()

      domReady: ->

      detached: ->

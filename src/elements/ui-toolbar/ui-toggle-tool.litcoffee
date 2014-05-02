A simple toggle button with a FontAwesome icon. Fires off an event indicating
the toggled state.

#Attributes
##togglechanged
This is the name of an event to fire when the toggle has changed.
##active
When present, the toggle is on.
##icon
Name of a the font-awesome style to use as the icon. If you really want
you can put any style names in here to use other than FontAwesome.

#Events
This fires a dynamic event based on `togglechanged`. Will fire a
`.on` and a `.off` suffixed event depending on the state.

    Polymer 'ui-toggle-tool',
      active: false
      attached: ->
        @addEventListener 'click', =>
          @active = not @active
        @activeChanged()
        document.addEventListener 'keydown', (e) =>
          return unless @hotkey
          
          key = if isNaN(@hotkey) then String.fromCharCode(e.keyCode).toLowerCase() else e.keyCode.toString()
          activeElem = document.activeElement.tagName.toLowerCase()

          if key is @hotkey and activeElem != 'textarea' and activeElem != 'input'
            @active = not @active

      activeChanged: ->
        if @active
          @fire "#{@togglechanged}.on"
          @$.tool.classList.add('active')
          @$.overlay.hide()
        else
          @fire "#{@togglechanged}.off"
          @$.tool.classList.remove('active')
          @$.overlay.show()
      tooltipChanged: ->
        $(@$.tool).popup
          inline: true
          content: @tooltip
          position: @tooltipPosition()


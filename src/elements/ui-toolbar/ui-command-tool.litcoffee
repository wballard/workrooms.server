A simple toggle button with a FontAwesome icon. Fires off an event indicating
the toggled state.

#Attributes
##command
This is the name of an event to fire when clicked.
##icon
Name of a the font-awesome style to use as the icon. If you really want
you can put any style names in here to use other than FontAwesome.

#Events
This fires a dynamic event based on `command`.

    bonzo = require('bonzo')

    Polymer 'ui-command-tool',
      attached: ->
        bonzo(@$.spinner).hide()
        @addEventListener 'click', =>
          @fire @command, @detail
          bonzo(@$.spinner).show()
          setTimeout =>
            bonzo(@$.spinner).hide()
          , 1000


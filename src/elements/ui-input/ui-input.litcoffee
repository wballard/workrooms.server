A input element is more than just a plain input, it adds autocomplete
and clear beharior (hit ESC), and provides icon styling.

#Attributes
##icon
Supply a `fa-` icon and it will appear in the left portion of the input.
##value
This is the string value of the input.
##placeholder
Text to show when there is not yet any input.

#Events
##autocomplete
This is a deleyed change event that fires after a keystroke timeout, which
is what you want when tying the text to an autocomplete.
##clear
Fires on escape, clearing out the text box. And when you just delete everything.

    _ = require('lodash')
    bonzo = require('bonzo')

    Polymer 'ui-input',
      attached: ->
        autocomplete = _.debounce =>
          @fire 'autocomplete', @$.input.value
        , 300
        @addEventListener 'keyup', (evt) =>
          if evt.keyCode is 27
            @$.input.value = ''
            @fire 'clear'
          else if @$.input.value
            autocomplete()
          else
            @fire 'clear'

Synch up the value property with the input control inside this element.

        @addEventListener 'change', (evt) =>
          @value = @$.input.value

Synch up the input control with the input property on this element.

      valueChanged: (oldValue, newValue) ->
        @$.input.value = newValue

This conditionally applies formatting to show an icon display via semantic-ui.

      iconChanged: (oldValue, newValue) ->
        if newValue?
          bonzo(@$.wrapper).addClass('icon').addClass('left')
          bonzo(@$.icon).show()
          bonzo(@$.icondisplay).addClass('fa').addClass(@icon)
        else
          bonzo(@$.wrapper).removeClass('icon').removeClass('left')
          bonzo(@$.icon).hide()
          @$.icondisplay.class = ""

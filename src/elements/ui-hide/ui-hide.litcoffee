Hide if hidden.

    bonzo = require('bonzo')
    _ = require('lodash')

    Polymer 'ui-hide',
      hideChanged: (oldValue, newValue) ->
        if _.keys(newValue or {}).length
          bonzo(@).hide()
        else
          bonzo(@).show()

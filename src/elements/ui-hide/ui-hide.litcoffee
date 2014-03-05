Hide if hidden.

    require('../elementmixin.litcoffee')

    Polymer 'ui-hide',
      hideChanged: (oldValue, newValue) ->
        if newValue
          @hideAnimated()
        else
          @showAnimated()
      showChanged: (oldValue, newValue) ->
        if newValue
          @showAnimated()
        else
          @hideAnimated()

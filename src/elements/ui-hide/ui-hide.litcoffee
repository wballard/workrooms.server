Hide if hidden.

    require('../elementmixin.litcoffee')

    Polymer 'ui-hide',
      hideChanged: ->
        console.log 'hide', @hide
        if @hide
          @hideAnimated()
        else
          @showAnimated()
      showChanged: ->
        if @show
          @showAnimated()
        else
          @hideAnimated()

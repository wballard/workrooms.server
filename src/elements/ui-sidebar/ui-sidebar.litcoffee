Sidebar, this is a nice place to hide controls out of the way.

jQuery can't seem to query the shadow DOM in here, so manual wrapping
of a selected element.

    Polymer 'ui-sidebar',
      attached: ->
      toggle: ->
        if @visible
          @hideAnimated()
        else
          @showAnimated()

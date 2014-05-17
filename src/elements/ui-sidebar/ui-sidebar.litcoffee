Sidebar, this is a nice place to hide controls out of the way.

    Polymer 'ui-sidebar',
      visibleChanged: ->
        if @visible
          @show()
        else
          @hide()

      trackStart: ->
        @size = parseInt(getComputedStyle(@)['width'])

      track: (evt) ->
        delta = evt['dx']
        @style['width'] = "#{@size - delta}px"

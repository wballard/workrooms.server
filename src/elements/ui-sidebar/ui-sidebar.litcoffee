Sidebar, this is a nice place to hide controls out of the way.

    Polymer 'ui-sidebar',

jQuery can't seem to query the shadow DOM in here, so manual wrapping
of a selected element.

      attached: ->
        @sidebar = $(@$.sidebar).sidebar()

      toggle: ->
        @sidebar.sidebar('toggle')

    Polymer 'ui-right-sidebar',

      attached: ->
        @sidebar = $(@$.sidebar).sidebar()

      toggle: ->
        @sidebar.sidebar('toggle')

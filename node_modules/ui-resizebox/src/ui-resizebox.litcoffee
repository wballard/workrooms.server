#ui-resizebox
This makes a resizeable panel, which by default will go in flow, but you
can easily make a docked resizer by using `absolute` positioning. Grab the
element on the `left` or `right` and resize away.

    Polymer 'ui-resizebox',

##Events

##Attributes and Change Handlers
###right
Just put this attribute on, and the resize bar handle will appear to the right.
###left
Sorta like `right`, but backwards.

##Methods

##Event Handlers
Use the touch tracking events to process a drag of the resize handle.

      trackStart: ->
        @size = parseInt(getComputedStyle(@)['width'])

      track: (evt) ->
        delta = evt['dx']
        if @right?
          delta *= -1
        @style['width'] = "#{@size - delta}px"

##Polymer Lifecycle

      created: ->

      ready: ->

      attached: ->

      domReady: ->

      detached: ->

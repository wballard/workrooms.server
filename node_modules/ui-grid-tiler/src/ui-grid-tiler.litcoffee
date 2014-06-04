#ui-grid-tiler
This is a space filling element that resists scrolling by making its child
elements evenly sized. By default this is centered, so that if you have
`inline-block` children, it will form as close to a Brady Bunch style grid as
possible.

This sets the width, but constraints the max height. This works well with forced
aspect ration tags like `video`.

    _ = require 'lodash'
    ResizeSensor = require './ResizeSensor'

##Events

    Polymer 'ui-grid-tiler',

##Attributes and Change Handlers

###aspectRatio
This acts as a multiplier on width. Default is 1.

###selector
When present, select these children -- otherwise get them all

###fill
Fill factor, defaults to `0.95`.

##Methods

Resize the children to fill in container, maintaining the aspect ratio
but being careful to not let the aspect ratio overflow the container.

      resize: ->
        children = @querySelectorAll(@selector) if @selector or @children
        scaleWidth = (@clientWidth / Math.ceil(Math.sqrt(children.length))) * @fill
        scaleHeight = (@clientHeight / Math.ceil(Math.sqrt(children.length))) * @fill
        aspectWidth = Number(@aspectRatio or 1) * scaleHeight
        scaleWidth = Math.min(aspectWidth, scaleWidth)
        _.each children, (tile) =>
          tile.style['width'] = "#{scaleWidth}px"
          tile.style['max-height'] = "#{scaleHeight}px"

##Event Handlers

      childrenMutated: ->
        @resize()
        @onMutation @, =>
          @childrenMutated()

##Polymer Lifecycle

      created: ->
        @fill = 0.95

      ready: ->

      attached: ->
        @sensor = new ResizeSensor @, =>
          @resize()
        window.addEventListener 'resize', =>
          @resize()
        @resize()
        @onMutation @, =>
          @childrenMutated()

      domReady: ->

      detached: ->

#ui-tooltip
This is a self resizing and positioning tooltip. To use it, just wrap it around
an element, then you get a tool tip on hover.

You can set content two ways `label="text"`, or with nested html like:

```html
<ui-tooltip>
  <span>wrapped element</span>
  <span tip>tooltip content</span>
</ui-tooltip>
```

Tooltips are hover driven, so aren't all the great for mobiles.


    Polymer 'ui-tooltip',

##Events
No custom events are fired.

##Attributes and Change Handlers
###label
Set this text attribute to show a simple text only tooltip.

##Methods
###position
This will place the tooltip in an optimal viewing position based on the client
screen size. This gets called automatically on hover.

      position: ->
        tip = @getBoundingClientRect()
        body = document.querySelector('body').getBoundingClientRect()
        xStep = document.documentElement.clientWidth / 3
        yStep = document.documentElement.clientHeight / 3
        offsetX = 'left'
        if tip.left < xStep*2
          offsetX = 'right'
        offsetY = 'up'
        if tip.top < yStep*2
          offsetY = 'down'
        @display= "#{offsetX} #{offsetY}"


##Event Handlers
Mouse motion is handled to automatically show and position the element so that
it can be seen easily.

      mouseenter: ->
        @position()
        @$.tooltip.classList.remove "hidden"

      mouseleave: ->
        @position()
        @$.tooltip.classList.add "hidden"


##Polymer Lifecycle
When the tooltip attaches to the DOM, it generates an initial position, which
will be updated dynamcially as elements are moved or scrolled.

      created: ->

      ready: ->

      attached: ->
        @position()

      domReady: ->

      detached: ->

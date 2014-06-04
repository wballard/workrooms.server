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


##Events
No custom events are fired.

##Attributes and Change Handlers
###label
Set this text attribute to show a simple text only tooltip.

##Methods
###position
This will place the tooltip in an optimal viewing position based on the client
screen size. This gets called automatically on hover.














##Event Handlers
Mouse motion is handled to automatically show and position the element so that
it can be seen easily.








##Polymer Lifecycle
When the tooltip attaches to the DOM, it generates an initial position, which
will be updated dynamcially as elements are moved or scrolled.







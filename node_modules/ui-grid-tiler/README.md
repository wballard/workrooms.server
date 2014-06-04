#ui-grid-tiler
This is a space filling element that resists scrolling by making its child
elements evenly sized. By default this is centered, so that if you have
`inline-block` children, it will form as close to a Brady Bunch style grid as
possible.

This sets the width, but constraints the max height. This works well with forced
aspect ration tags like `video`.



##Events


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










##Event Handlers





##Polymer Lifecycle














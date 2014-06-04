#ui-toolbar-button
A simple, [FontAwesome](http://fortawesome.github.io/Font-Awesome/) based
tool button. This supports:

* active state toggling
* hotkey mapping
* clicking

Check out [demo.html](demo.html) to see a sample.


##Events
###click
Good old click, handle this to do the deed. This will also be fired when
the `hotkey` is pressed.

##Attributes and Change Handlers
###active
Toggle state for the button, `true` is on.
###enabled
Enable or disable the button.
###toggle
Automatically enable or disable on `click`.
###icon
This is a `fa-` icon name.
###hotkey
Character or character code to enable hotkeys. For example 32 is hotkey space.
###selected
You can use a tool icon as a menu item, when it is `selected` it stands out.






##Methods

##Event Handlers
Mouse and action handling is via PointerEvents. These are used to trigger
the animation styles.
















##Polymer Lifecycle







This element hooks to the document to process hotkeys.











#ui-toolbar
This is a very simple toolbar that you fill up with
[ui-toolbar-button](https://github.com/wballard/ui-toolbar) elements.

Check out [demo.html](demo.html) to see a sample.


##Events

##Attributes and Change Handlers

##Methods

##Event Handlers

##Polymer Lifecycle






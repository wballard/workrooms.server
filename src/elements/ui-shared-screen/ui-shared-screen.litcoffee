A shared screen representation inside a workroom. This lets you see all the
shared screens and either:

* connect, click to connect a new tab to the screen share
* close, removing the screen share from the room

This doesn't do any signalling, just fires off an event when a screenshare is
fully ready.

#Events
##screenshared
Fired when the screen is fully ready to be shared.

    Polymer 'ui-shared-screen',
      snapshotTaken: ->
        @fire 'screenshared', @screen

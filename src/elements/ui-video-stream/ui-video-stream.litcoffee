Show a video stream with user interface.

#Attributes
##sourcemutedvideo
##sourcemutedaudio
##mirror
##mutedaudio

#Events
##stream

#Methods
##display(stream)

    _ = require('lodash')
    bonzo = require('bonzo')

    SNAPSHOT_TIMEOUT = 30 * 1000

    Polymer 'ui-video-stream',

      ready: ->
        bonzo(@$.snapshot).hide()
        bonzo(@$.sourcemutedaudio).hide()

Cool. Static snapshots to use when the video is muted. This gets defined when
the video plays.

      attached: ->
        @$.video.addEventListener 'canplay', =>
          width = parseInt(getComputedStyle(@$.video).getPropertyValue('width').replace('px',''))
          height = @$.video.videoHeight / (@$.video.videoWidth/width)
          @$.video.setAttribute('width', width)
          @$.video.setAttribute('height', height)
          @$.takesnapshot.setAttribute('width', width)
          @$.takesnapshot.setAttribute('height', height)
          takeSnapshot = =>
            width = parseInt(getComputedStyle(@$.video).getPropertyValue('width').replace('px',''))
            height = @$.video.videoHeight / (@$.video.videoWidth/width)
            ctx = @$.takesnapshot.getContext('2d')
            ctx.drawImage(@$.video, 0, 0, width, height)
            @$.snapshot.setAttribute('src', @$.takesnapshot.toDataURL('image/png'))
          takeSnapshot()
          setInterval =>
            if not @hasAttribute('sourcemutedvideo') or @getAttribute('sourcemutedvideo') is 'false'
              takeSnapshot()
          , SNAPSHOT_TIMEOUT

Looking for attributes to mute. This is a neat trick as these are attributes
that trigger by presence, so we can hit them with the ?

      attributeChanged: (name, oldValue, newValue) ->
        if name is 'sourcemutedaudio'
          if newValue?
            bonzo(@$.sourcemutedaudio).show()
          else
            bonzo(@$.sourcemutedaudio).hide()
        if name is 'sourcemutedvideo'
          if newValue?
            bonzo(@$.video).hide()
            bonzo(@$.snapshow).show()
          else
            bonzo(@$.video).show()
            bonzo(@$.snapshow).hide()

      display: (stream) ->
        if @hasAttribute('mutedaudio')
          @$.video.setAttribute('muted', '')
        else
          @$.video.removeAttribute('muted')
        if @hasAttribute('mirror')
          bonzo(@$.video)
           .css('-webkit-transform', 'scaleX(-1)')
        @$.video.src = URL.createObjectURL(stream)
        @$.video.play()
        @fire 'stream', stream

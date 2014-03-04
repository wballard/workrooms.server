Screenshare 'room' fills up the entire tab with screen sharing.

    getUserMedia = require('getusermedia')

    Polymer 'screenshare-room',
      screen: null
      ready: ->
        chrome.tabs.getCurrent (tab) =>
          chrome.desktopCapture.chooseDesktopMedia ['screen'], tab, (streamId) =>
            constraints =
              audio: false
              video:
                mandatory:
                  chromeMediaSource: "desktop"
                  chromeMediaSourceId: streamId
                  maxWidth: screen.width
                  maxHeight: screen.height
            getUserMedia constraints, (err, stream) =>
              console.log 'media screen', err, stream
              @screen = stream
              window.ss = @screen
              console.log @screen, @screen.getVideoTracks()[0]
              @$.video.src = URL.createObjectURL(@screen)
              @$.video.play()

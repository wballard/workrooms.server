This element is a bit of an adapter to turn the API oriented local stream
into a DOM element, all Polymer style...

#Attributes
##stream
This is the actual stream object, which will have video and audio.
##video
If present, use the camera.
##audio
If present, use the microphone.

#Events
##error
Bad stuff. Fires.
##localstream
Fires when a stream is available, also after then `stream` property is set.

    getUserMedia = require('getusermedia')
    getScreenMedia = require('getscreenmedia')

    Polymer 'local-stream',
      attached: ->
        mediaConstraints =
          video: @hasAttribute('video')
          audio: @hasAttribute('audio')
        getUserMedia mediaConstraints, (err, stream) =>
          if err
            @fire 'error', err
          else
            @stream = stream
        getScreenMedia (err, stream) =>
          if err
            @fire 'error', err
          else
            @screenstream = stream

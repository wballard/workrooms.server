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

    getUserMedia = require 'getusermedia'
    _ = require 'lodash'

    Polymer 'local-stream',
      audioChanged: ->
        if @stream
          @stream?.getAudioTracks()?.forEach (x) => x.enabled = @audio

Toggle the stream to truly mute the video signal. When disabling, put in a
delay so that on the far side, animation has time to switch over to a muted
image. There is no need to do this when turning it back on as the mute image
already has the video covered and will fade away on the far side.

      videoChanged: ->
        delay = 1000 if not @video
        if @stream
          setTimeout =>
            @stream?.getVideoTracks()?.forEach (x) => x.enabled = @video
          , delay

#Polymer Lifecycle
On attach, grab access to the user camera so that we have a stream.

      attached: ->
        MediaStreamTrack.getSources (sourceInfos) ->
          console.log sourceInfos

        mediaConstraints =
          video:
            mandatory:
              maxWidth: 320
              maxHeight: 240
          audio: true
        getUserMedia mediaConstraints, (err, stream) =>
          if err
            console.log err
            @fire 'error', err
          else
            @stream = stream

      detached: ->
        clearInterval @volumePoller

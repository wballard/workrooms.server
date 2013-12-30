
Platform = require('polyfill-webcomponents')
require('./style.less')
getUserMedia = require('getusermedia')
attachMediaStream = require('attachmediastream')
hark = require('hark')

###
Video for yourself, this will get your local stream and show it.

#Events
selfvideostream: event.details.stream contains the local stream
###
class LocalVideo extends HTMLElement
  mediaConstraints:
    audio: true
    video:
      mandatory:
        maxWidth: 320
        maxHeight: 240
  createdCallback: ->
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = '<video id="display"></video>'
  enteredViewCallback: =>
    display = @shadow.querySelector('#display')
    getUserMedia @mediaConstraints, (err, stream) =>
      if err
        @.dispatchEvent new CustomEvent('error',
          bubbles: true
          detail:
            stream: stream
            error: err
        )
      else
        @.dispatchEvent new CustomEvent('localvideostream',
          bubbles: true
          detail:
            stream: stream
        )
        attachMediaStream stream, display, muted: true
        speech = hark stream, {}
        speech.on 'speaking', ->
          display.classList.add('highlight')
        speech.on 'stopped_speaking', ->
          display.classList.remove('highlight')


module.exports =
  LocalVideo: document.register 'local-video', prototype: LocalVideo.prototype

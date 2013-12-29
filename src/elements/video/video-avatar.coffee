###
Video avatars, so you can talk to one another.
###

Platform = require('polyfill-webcomponents')
require('./style.less')
bean = require('bean')
getUserMedia = require('getusermedia')
attachMediaStream = require('attachmediastream')
hark = require('hark')
bonzo = require('bonzo')
rfile = require('rfile')

#pull in templates here, needs to be at root of the file for
#browserify
videoTemplate = require('./video.html')()

#Video for yourself, this will get your local stream and show it
class SelfVideoAvatar extends HTMLElement
  mediaConstraints:
    audio: true
    video:
      mandatory:
        maxWidth: 320
        maxHeight: 240
  createdCallback: ->
    console.log videoTemplate
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = videoTemplate
  enteredViewCallback: =>
    display = @shadow.querySelector('#display')
    getUserMedia @mediaConstraints, (err, stream) =>
      if err
        console.log err
      else
        attachMediaStream stream, display
        speech = hark stream, {}
        speech.on 'speaking', ->
          bonzo(display).addClass('highlight')
        speech.on 'stopped_speaking', ->
          bonzo(display).removeClass('highlight')



module.exports =
  SelfVideoAvatar: document.register 'self-video-avatar', prototype: SelfVideoAvatar.prototype

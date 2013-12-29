###
Build and control the entire conference page
###

SelfVideoAvatar = require('./elements/video/video-avatar.coffee').SelfVideoAvatar
domready = require('domready')

domready ->
  console.log 'conference tab'
  document.body.appendChild new SelfVideoAvatar()

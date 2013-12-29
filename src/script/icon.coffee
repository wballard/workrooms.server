###
Maintain a dynamic extension icon with here, this will show a default from our
glyphs, and then replace it with an image capture mini avatar. A really tiny avatar.
###
canvas = null
module.exports =
  prepare: ->
    $('body').append('<canvas id="extensionIcon" width="19" height="19"></canvas>')
    canvas = document.getElementById('extensionIcon')
  update: ->
    context = canvas.getContext('2d')
    context.font = "1em GLGlyphs"
    context.textBaseline = "top"
    context.fillText(String.fromCharCode(0x51), 2, 2)
    image = context.getImageData(0, 0, 19, 19)
    chrome.browserAction.setIcon imageData: image

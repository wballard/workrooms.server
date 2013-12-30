Platform = require('polyfill-webcomponents')
bean = require('bean')

###
Maintain a dynamic extension icon with here, this will show a default from our
glyphs, and then replace it with an image capture mini avatar. A really tiny avatar.

TODO: use the tiny avatar instead of the icon
TODO: hook up badges to indicate the number of folks in your conference
###
class ExtensionIcon extends HTMLElement
  createdCallback: ->
    size = @size = 16
    @shadow = @.createShadowRoot()
    @shadow.innerHTML = """
    <canvas id="extensionIcon" width="#{size}" height="#{size}"></canvas>
    """
  enteredViewCallback: ->
    size = @size
    canvas = @shadow.querySelector('#extensionIcon')
    context = canvas.getContext('2d')
    context.font = "#{size-2}px FontAwesome"
    context.textBaseline = "top"
    context.fillStyle = "#666"
    context.fillText(String.fromCharCode(0xf0c0), 0, 0)
    image = context.getImageData(0, -1, size, size)
    chrome.browserAction.setIcon imageData: image
    bean.fire(@, 'change')

module.exports = document.register 'extension-icon',
  prototype: ExtensionIcon.prototype


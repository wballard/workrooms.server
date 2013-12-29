###
Maintain a dynamic extension icon with here, this will show a default from our
glyphs, and then replace it with an image capture mini avatar. A really tiny avatar.

This is implemented as a custom element, using webcomponents.
###

Platform = require('polyfill-webcomponents')
bean = require('bean')

#I know this seems odd for me, but elements are in fact quite 'objecty'
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


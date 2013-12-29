###
Maintain a dynamic extension icon with here, this will show a default from our
glyphs, and then replace it with an image capture mini avatar. A really tiny avatar.

This is implemented as a custom element, using webcomponents.
###

Platform = require('polyfill-webcomponents')


#I know this seems odd for me, but elements are in fact quite 'objecty'
class ExtensionIcon extends HTMLElement
  createdCallback: ->
    size = 16
    shadow = @.createShadowRoot()
    shadow.innerHTML = """
    <canvas id="extensionIcon" width="#{size}" height="#{size}"></canvas>
    """
    @.appendChild shadow
    canvas = @.querySelector('#extensionIcon')
    context = canvas.getContext('2d')
    context.font = "#{size}px GLGlyphs"
    context.textBaseline = "top"
    context.fillText(String.fromCharCode(0x51), 0, 0)
    image = context.getImageData(0, 0, size, size)
    chrome.browserAction.setIcon imageData: image

module.exports = document.register 'extension-icon',
  prototype: ExtensionIcon.prototype


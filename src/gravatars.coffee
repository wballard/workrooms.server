###
This is a content script that will detect and augment gravatars
to allow calling.
###

MutationSummary = require('MutationSummary')
require('./elements/mixin.coffee')
urlparse = require('urlparse')

gravatarRegex = new RegExp('gravatar')

processImageForGravatar = (img) ->
  if img?.src?.match(gravatarRegex)
    if not img.parent().hasClass('callable')
      parent = img.parent()
      img.addClass('called')
      marginRight = getComputedStyle(img)['margin-right']
      marginTop = getComputedStyle(img)['margin-top']
      float = getComputedStyle(img)['float']
      display = getComputedStyle(img)['display']
      img.css('margin-right': 0, 'margin-top': 0, 'float': 'none', 'display': 'inline')
      elem = img.replaceWith("""
      <span class="callable" style="display: #{display}; margin-right: #{marginRight}; margin-top: #{marginTop}; float: #{float};">
        #{img.outerHTML}
        <i class="fa fa-video-camera video-call"></i>
      </span>
      """)
      parent.querySelector('.video-call').on 'click', (evt) ->
        evt.preventDefault()
        gravatarToCall = urlparse(img.src).path.split('/')?[2]
        chrome.runtime.sendMessage
          call: true
          gravatar: gravatarToCall

#everything on start, and look for mutation
document.querySelectorAll('img').forEach processImageForGravatar
observer = new MutationSummary
  callback: (summaries) ->
    summaries.forEach (summary) ->
      summary.added?.forEach processImageForGravatar
      summary.attributeChanged?.src?.forEach processImageForGravatar
  queries: [
    {element: 'img', elementAttributes: 'src'}
  ]

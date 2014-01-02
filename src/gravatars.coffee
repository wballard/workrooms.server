###
This is a content script that will detect and augment gravatars
to allow calling.
###

MutationSummary = require('MutationSummary')
require('./elements/mixin.coffee')

console.log 'injected'
gravatarRegex = new RegExp('gravatar')
do ->
  document.querySelectorAll('img').forEach (img) ->
    if img.getAttribute('src').match(gravatarRegex) and img.width >= 20
      if not img.parent().hasClass('callable')
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

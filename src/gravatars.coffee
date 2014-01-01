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
    if img.getAttribute('src').match(gravatarRegex)
      exists = false
      img.previous().each (sib) ->
        exists = sib.hasClass('callable') or exists
      if not exists
        img.before("""<i class="fa fa-video-camera callable"></i>""")

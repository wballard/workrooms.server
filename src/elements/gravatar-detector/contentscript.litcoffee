This is a content script that will detect and augment gravatars
with video calls.

    MutationSummary = require('../../../vendor/mutation-summary.js')
    urlparse = require('urlparse')
    bonzo = require('bonzo')
    qwery = require('qwery')

    gravatarRegex = new RegExp('gravatar')

    processImageForGravatar = (img) ->
      if img?.src?.match(gravatarRegex)

Try to capture the original styling and then build up a similarly styled
replacement.

        #capture original style
        marginRight = getComputedStyle(img)['margin-right']
        marginTop = getComputedStyle(img)['margin-top']
        float = getComputedStyle(img)['float']
        display = getComputedStyle(img)['display']
        html = img.outerHTML
        gravatarToCall = urlparse(img.src).path.split('/')?[2]
        #and now build up the replacement
        img = bonzo(img)
        if not img.parent().hasClass('callable')
          parent = img.parent()
          img.addClass('called')
          img.css('margin-right': 0, 'margin-top': 0, 'float': 'none', 'display': 'inline')
          elem = img.replaceWith("""
          <span class="callable" style="display: #{display}; margin-right: #{marginRight}; margin-top: #{marginTop}; float: #{float};">
            #{html}
            <i class="fa fa-video-camera video-call"></i>
          </span>
          """)
          parent[0].querySelector('.video-call').addEventListener 'click', (evt) ->
            evt.preventDefault()
            console.log 'gravatar call', gravatarToCall

Here is the result, sending a message to `call` with a `gravatar` id, this
is the *click to dial*.

            chrome.runtime.sendMessage
              call: true
              to:
                gravatar: gravatarToCall

Now, look all through the document for all images and process em!

    qwery('img').forEach processImageForGravatar
    observer = new MutationSummary
      callback: (summaries) ->
        summaries.forEach (summary) ->
          summary.added?.forEach processImageForGravatar
          summary.attributeChanged?.src?.forEach processImageForGravatar
      queries: [
        {element: 'img', elementAttributes: 'src'}
      ]

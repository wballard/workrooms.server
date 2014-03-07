This is the application -- the background page that ties it all together.

Originally, this was in Polymer, but 0.2.0 broke custom element support in background pages
which in some sense it no big deal as this isn't really a 'page' at all. So -- code it is!

    ExtensionIcon = require('../scripts/extension-icon.litcoffee')
    icon = new ExtensionIcon()

# What is It?
A workroom is a place to collaborate online, just like if you were in
person.

# How does it Work?
People drop by each other, just like dropping by your desk. If multiple
folks drop by, you are all together.

# How do I get Started?

1. Install the plugin
2. Click the icon
3. Invite someone by email address

That's it, no registration required.

# Features

* Video / Audio / Text Chat (with markdown!)
* Screen and Window sharing
* Highlighting and presence Gravatars (perfect for StackOverflow and
  Github)

# Architecture

## Client
Client is a browser extension, this is to give you presence without
requiring you to go to a place.

## Server
Server provides:

* Signalling, to set up chats
* Presence, seeing who is on
* Invitations, checks presence, then fails back to email
* Plugin auto update and delivery

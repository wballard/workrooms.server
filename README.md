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
This uses browserify and a bootstrap shim to hot reload during
development. All you need to do is:

```
npm install
npm start
```

See that it is doing, then you can fire up and load this directory as a
bare Chrome extension. If you watch in the background page, you'll see a
message flash when new code is detected and a hot load is needed.

## Client
Client is a browser extension, this is to give you presence without
requiring you to go to a place.

## Server
Server provides:

* Signalling, to set up chats
* Presence, seeing who is on
* Invitations, checks presence, then fails back to email
* Plugin auto update and delivery

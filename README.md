# What's the Problem?
Video conference and screen share isn't as simple as dropping someone's
desk.

# What is It?
One click video conference, just click on any GitHub gravatar and start
working together.

# How does it Work?
With an always on Chrome plugin, a simple WebSocket
[server](https://github.com/wballard/workrooms.server), and WebRTC, you
can pair program and collaborate with one click.

# Build
This uses browserify and a bootstrap shim to hot reload during
development. All you need to do is:

```
npm install
grunt watch
```

See that it is doing, then you can fire up and load this directory as a
bare Chrome extension. If you watch in the background page, you'll see a
message flash when new code is detected and a hot load is needed.

You will also need the
[server](https://github.com/wballard/workrooms.server).


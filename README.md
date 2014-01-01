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

This is a Chrome Extension (chrome://extensions/), so you will need to
*Load unpacked extension...* pointed at this checkout.


You will also need the
[server](https://github.com/wballard/workrooms.server).

And -- poof, you will get videos of yourself.


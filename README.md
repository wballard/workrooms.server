# What's the Problem?
Video conference and screen share isn't as simple as dropping someone's
desk.

# What is It?
One click video conference, just click on any GitHub gravatar and start
working together.

# How does it Work?
With google chrome, WebRTC and some basic websocket signaling, workrooms allows you to connect and collaborate without any logins or information other than a unique (arbitrary) url.


# Build
This uses browserify and a bootstrap shim to hot reload during
development. All you need to do is:

```
npm install
npm start
```

And -- poof, you will get videos of yourself on https://localhost:9001


You can also set up a watch to update the app as assets are changed using"

```
npm test
```




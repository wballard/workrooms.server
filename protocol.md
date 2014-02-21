#Overview
Workrooms communicates between clients using a combination of
*signalling*, which relays through a WebSocket server and peer-to-peer
*messages* through WebRTC. The overall metaphor is one of distributed
events and event handling, not one of request/response.

All messages are designed as network `CustomEvents`. This is a very
JavaScript feeling design, but is simple to follow. All messages look
like:

```
{
  type: 'string',
  detail: {}
}
```

##type
This string is the *event name* for listening.

##detail
This object is the event specific information.

#Message Pattern
All clients are uniquely identified on each run, in this fashion no
identifier can be captured and re-used over the long term. This is as
much a security feature as it is an effort to keep the protocol
stateless and avoid the need for a durable registration database.

The signalling server is stateless, keeping all information in memory on
a per connection basis. When a client disconnects, this data is erased,
effectively meaning you can remove yourself from the network by simply
shutting down the client.

Signalling is *connection oriented*, so clients don't need to send along a
*from* or *id* on each message, as the server can maintain this with
their socket connection. This client identifier is thus a `sessionid`.

##Startup Phase
On start, each client allocates `sessionid` used for the runtime life
of the client.

###register
On connection or reconnection after a network interruption, a client
must signal:
```
{
  type: 'register',
  detail: {
    sessionid: sessionid,
    calls: [calls...]
  }
}
```

Initially, calls is an empty array, but on reconnect will contain
metadata of active calls in the client that were supplied by
`inboundcall` and `outboundcall`.

###userprofile
Once a client has captured a local video stream, authenticated via
OAuth, and fetch a userprofile from the OAuth source, profiles are
signalled:

```
{
  type: 'userprofile',
  detail: {
    github: {...}
  }
}
```

This profile is used to drive the signalling server directory service to
search for other users.

##Connecting Phase
Calls are connected between clients using their `sessionid`.

All calls have an outbound (you call) and an inbound (you were called) side
to match up with WebRTC's expectations. The client that starts the call
will become the outbound side.

All calls have a .id which is unique to each call, and is used
as the correlation key between the inbound and outbound side
to set up peer-peer traffic.

###call
Starts up the call connection sequence.
```
{
  type: 'call',
  detail: {
    to: to_sessionid
  }
}
```

###outboundcall
The server sends this back to the calling side if the call can be
completed.
```
{
  type: 'outboundcall',
  detail: {
    outbound: true,
    callid: callid,
    fromsessionid: sessionid,
    tosessionid: to_sessionid,
    userprofiles: to_userprofiles
  }
}
```

###inboundcall
The server sends this back to the called side if the call can be
completed.
```
{
  type: 'inboundcall',
  detail: {
    inbound: true,
    callid: callid,
    fromsessionid: sessionid,
    tosessionid: to_sessionid,
    userprofiles: from_userprofiles
  }
}
```

##Connected State
When connected, calls can be modified by either side by relaying messages
though the signalling server.

###hangup
A hangup message from a connected client hangs up all passed calls by
looking up the counterparty sockets by sessionid, calls by callid. Once
a call to hang up is found, it is signalled to both peers of the call,
and the call is removed from the signalling server.

When a connected client receives as hangup from the server, it is
responsible for remove the designated call from itself and ending the
RTC connection.
```
{
  type: 'hangup',
  detail: {
    calls: [
      {
        callid: callid,
        sessionid: from_sessionid,
      }, ...
    ]
  }
}
```

##Other

###autocomplete
This is an autocompleting search mechanism.
```
{
  search: 'query',
  results: [{
    sessionid: sessionid,
    userprofiles: userprofiles
  }]
}
```
Sending to the server you don't need to supply results, it will be
filled in.

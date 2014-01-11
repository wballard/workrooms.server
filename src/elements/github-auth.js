//This code was borrowed and edited down from the Google oauth sample
var gh = (function() {
  'use strict';

  var tokenFetcher = (function() {
    var redirectUri = 'https://' +
      chrome.runtime.id +
      '.chromiumapp.org/provider_cb';
    console.log(redirectUri);
    var redirectRe = new RegExp(redirectUri + '[#\?](.*)');
    var access_token = null;

    return {
      getToken: function(clientId, clientSecret, callback) {
        // In case we already have an access_token cached, simply return it.
        if (access_token) {
          callback(null, access_token);
          return;
        }

        var options = {
          'interactive': true,
          url:'https://github.com/login/oauth/authorize?client_id=' + clientId +
          '&reponse_type=token' +
            '&access_type=online' +
            '&redirect_uri=' + encodeURIComponent(redirectUri)
        }
        chrome.identity.launchWebAuthFlow(options, function(redirectUri) {
          if (chrome.runtime.lastError) {
            callback(JSON.stringify(chrome.runtime.lastError));
            return;
          }
          var matches = redirectUri.match(redirectRe);
          if (matches && matches.length > 1)
            handleProviderResponse(parseRedirectFragment(matches[1]));
          else
            callback('Invalid redirect URI');
        });

        function parseRedirectFragment(fragment) {
          var pairs = fragment.split(/&/);
          var values = {};
          pairs.forEach(function(pair) {
            var nameval = pair.split(/=/);
            values[nameval[0]] = nameval[1];
          });
          return values;
        }

        function handleProviderResponse(values) {
          if (values.hasOwnProperty('access_token'))
            setAccessToken(values.access_token);
          // If response does not have an access_token, it might have the code,
          // which can be used in exchange for token.
          else if (values.hasOwnProperty('code'))
            exchangeCodeForToken(values.code);
          else
            callback('Neither access_token nor code avialable.');
        }

        function exchangeCodeForToken(code) {
          var xhr = new XMLHttpRequest();
          xhr.open('GET',
                   'https://github.com/login/oauth/access_token?' +
                   'client_id=' + clientId +
                     '&client_secret=' + clientSecret +
                     '&redirect_uri=' + redirectUri +
                     '&code=' + code);
                   xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                   xhr.setRequestHeader('Accept', 'application/json');
                   xhr.onload = function () {
                     // When exchanging code for token, the response comes as json, which
                     // can be easily parsed to an object.
                     if (this.status === 200) {
                       var response = JSON.parse(this.responseText);
                       if (response.hasOwnProperty('access_token')) {
                         setAccessToken(response.access_token);
                       } else {
                         callback('Cannot obtain access_token from code.');
                       }
                     } else {
                       callback('Code exchange failed');
                     }
                   };
                   xhr.send();
        }

        function setAccessToken(token) {
          access_token = token;
          callback(null, access_token);
        }
      },

      removeCachedToken: function(token_to_remove) {
        if (access_token == token_to_remove)
          access_token = null;
      }
    }
  })();

  function xhrWithAuth(clientId, clientSecret, method, url, callback) {
    var retry = true;
    var access_token;

    getToken();

    function getToken() {
      tokenFetcher.getToken(clientId, clientSecret, function(error, token) {
        if (error) {
          callback(error);
          return;
        }

        access_token = token;
        requestStart();
      });
    }

    function requestStart() {
      var xhr = new XMLHttpRequest();
      xhr.open(method, url);
      xhr.setRequestHeader('Authorization', 'Bearer ' + access_token);
      xhr.onload = requestComplete;
      xhr.send();
    }

    function requestComplete() {
      if ( ( this.status < 200 || this.status >=300 ) && retry) {
        retry = false;
        tokenFetcher.removeCachedToken(access_token);
        access_token = null;
        getToken();
      } else {
        callback(null, this.status, this.response);
      }
    }
  }

  function getUserInfo(clientId, clientSecret, callback) {
    function onUserInfoFetched(error, status, response) {
      if (!error && status == 200) {
        callback(undefined, JSON.parse(response));
      } else {
        callback(error);
      }
    }
    xhrWithAuth(clientId,
                clientSecret,
                'GET',
                'https://api.github.com/user',
                onUserInfoFetched);
  }

  return {
    login: function(clientId, clientSecret, callback) {
      tokenFetcher.getToken(clientId, clientSecret, function(error, access_token) {
        console.log('logged in', error, access_token);
        if (error) callback(error);
        else getUserInfo(clientId, clientSecret, callback);
      })
    }
  };
})();


module.exports = gh;

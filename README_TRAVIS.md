puppet-webhooks Travis-ci integration
=====================================

WARNING: Travis-ci support is incomplete. This only documents existing behavior.

Authentication
----

[post-build-notifications]: http://about.travis-ci.org/docs/user/notifications/

HTTP requests to the `/event/travis` endpoint must be validated that they
originated from Travis-ci. Github and Travis. Travis-ci post-build notifications
are sent with an `AUTHORIZATION` header containing the pattern
`#{username}/#{repository}#{TRAVIS_AUTH_TOKEN}`. In order to receive events from
Travis-ci, the `TRAVIS_AUTH_TOKEN` environment variable must be set to match the
Travis token of the Github user configured to interact with the Travis-ci API.

For more information, see the Travis [post build notification
documentation][post-build-notifications].

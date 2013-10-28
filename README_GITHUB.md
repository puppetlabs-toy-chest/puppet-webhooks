Puppet-webhooks Github integration
==================================

puppet-webhooks supports Github as an event source.

Environment variables
---

### GITHUB_ACCOUNT and GITHUB_TOKEN

The `GITHUB_ACCOUNT` and `GITHUB_TOKEN` variables are used to authenticate
against the Github API service. These variables must be specified, as only 60
unauthenticated requests against the Github API can be made in an hour from a
single IP address.

[github-token-gen]: https://help.github.com/articles/creating-an-access-token-for-command-line-use

Note that the Github token can be an oauth token as well as a user password,
and the two can be [used interchangeably][github-token-gen].

### GITHUB_EVENT_OUTPUTS

The `GITHUB_EVENT_OUTPUTS` variable determines where Github events should be
sent to. Supported outputs are 'jira' and 'trello'. Defaults to Trello.

### GITHUB_X_HUB_SIGNATURE_SECRET

[authednotify]: http://pubsubhubbub.googlecode.com/git/pubsubhubbub-core-0.3.html#authednotify

The `GITHUB_X_HUB_SIGNATURE_SECRET` variable is a SHA256 value that acts as a
shared secret between puppet-webhooks and Github. It is used to validate the
authenticity of a Github event by generating a signature of the message based on
the shared secret. This value must be specified, otherwise no API events will be
able to be received by the webhook server. For more information, see the
[PubSubHubBub authenticated content distribution documentation][authednotify].

[github-signature]: https://github.com/github/github-services/blob/master/lib/services/web.rb

Github has an example implementation of the shared secret validation on their
[github services repository][github-signature].

#### Configuring the signature secret

Configuring the Github shared secret must be done via the Github API, as it is
not exposed via the repository settings/webhooks. This can be done by using the
`bin/github-template-hook` script to generate the required JSON, modifying it to
include the shared secret, and then submitting it to the Github API with the
`bin/github-new-hook` script.

- - -

Alternately, this can be done by generating the shared secret with the
following:

    dd if=/dev/random bs=1k count=1 | openssl sha256 | awk '{print $2}'
    #=> 845f1e81063d2808823abc810f45cca2b329b87fd5e81d6649219ed6e0560e12

And then submitting it with this command:

    curl -i -u jeffmccune -d '
    {
      "name": "web",
      "active": true,
      "events": ["pull_request", "issues"],
      "config": {
        "url": "http://event.endpoint/event/github",
        "secret": "845f1e81063d2808823abc810f45cca2b329b87fd5e81d6649219ed6e0560e12"
        "content_type": "json"
      }
    }' https://api.github.com/repos/puppetlabs/puppet/hooks

- - -

After configuring the Github endpoint, puppet-webhooks needs to have the shared
secret available as the `GITHUB_X_HUB_SIGNATURE_SECRET` environment variable.
This can be done with heroku with the following:

    heroku config:set GITHUB_X_HUB_SIGNATURE_SECRET="845f1e81063d2808823abc810f45cca2b329b87fd5e81d6649219ed6e0560e12"

Helper scripts
---

A number of helper scripts have been included in this repository in the `bin/`
directory to simplify interacting with the Github API.

Puppet WebHooks
====

[![Build Status](https://travis-ci.org/puppetlabs/puppet-webhooks.png?branch=master)](https://travis-ci.org/puppetlabs/puppet-webhooks)

puppet-webhooks acts as a relay from Github and other services to Jira and
Trello, so that events on a Github project automatically create and update Jira
issues or Trello cards.

Importing
----

Existing PRs can be imported to the Trello board by exporting the necessary
environment variables and then issuing:

    $ rake import:prs REPO=puppetlabs/puppet
    $ rake jobs:worksilent

This will queue jobs for each PR currently open, then run a worker to process
the queue.  This can be done on a standalone system, with a sqlite database
configured in `config/database.yml`, after running `rake db:migrate`.

Individual PRs can be imported by also specifying "PR=123".

Examples
====

The spec tests are configured to use an in-memory sqlite3 database with
ActiveRecord and DelayedJob.  The rake tasks, spec helper, and application
itself should use the `PuppetLabs::Webhook.setup_environment` method to setup
the database connection.

To run the specs:

    $ bundle exec rake spec RACK_ENV=test

Maintainer
----

Jeff McCune <jeff@puppetlabs.com>

[heroku]: https://www.heroku.com

License
====

Apache 2.0.  Please see the LICENSE file for more information.

EOF

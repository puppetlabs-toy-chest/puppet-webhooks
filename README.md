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

Interactive Exploration
====

This code base is designed to be relatively straight forward to work with
interactively using tools like `irb` and `pry`.  Here's how I quickly rig up
instances of the jobs that are performed by this web app.  First, make sure you
have an example of the JSON data stored in the fixtures directory.  For this
example I'm going to use `spec/unit/fixtures/example_pull_request_closed.json`.

Next, add something like the following two methods to `~/.irbrc`.  The goal is
to quickly get a reference to an instance of the job that will be performed.

```ruby
##
# jjm_load_path sets up the load path to include both the spec/ and lib/
# directories.  This method makes the assumption that the present working
# directory is the base directory of the project
def jjm_load_path
  spec = File.expand_path("spec")
  $LOAD_PATH.delete spec
  $LOAD_PATH.unshift spec
  path = File.expand_path("lib")
  $LOAD_PATH.delete path
  $LOAD_PATH.unshift path
  $LOAD_PATH[0..1]
end

##
# jjm_prjob creates an instance of TrelloPullRequestJob suitable for
# interactive testing.
def jjm_prjob(fixture = "example_pull_request_closed.json")
  jjm_load_path
  require 'puppet_labs/pull_request_controller'
  require 'spec_helper'
  payload = read_fixture(fixture)
  pull_request = PuppetLabs::PullRequest.new(:json => payload)
  job = PuppetLabs::TrelloPullRequestJob.new
  job.pull_request = pull_request
  job
end
```

Next, make sure your environment variables are configured and exported.  In
order to interact with Trello, you'll need the following environment variables.
If you already have a copy of this app running in Heroku it's super easy to get
these variables set using `heroku config --shell | grep TRELLO | xargs -n1 echo
export > trello_env.sh`, then simply `eval "$(trello_env.sh)"`.

    TRELLO_APP_KEY
    TRELLO_SECRET
    TRELLO_TARGET_LIST_ID
    TRELLO_USER_TOKEN

Finally, make sure you're current working directory is in the root of the
application repository and you should be ready to go.

    $ bundle exec irb
    Welcome to IRB. You are using ruby 1.9.3p327 (2012-11-10) [x86_64-darwin12.2.0]. Have fun ;)
    >> job = jjm_prjob; nil #=> nil
    >> job.perform #=> true
    Processing: (PR puppet-webhooks/2) Test Pull Request 1
    Done Processing: (PR puppet-webhooks/2) Test Pull Request 1
    >>

And you should see the results right on the board.

![Trello Activity](https://dl.dropbox.com/u/469429/pics/trello_activity.png)

Stick a `require 'pry'; binding.pry` statement inside of the `perform` method
and you can dive right into the method itself.

Maintainer
----

Jeff McCune <jeff@puppetlabs.com>

[heroku]: https://www.heroku.com
[dashboard]: https://dashboard.heroku.com/apps
[quickstart]: https://devcenter.heroku.com/articles/quickstart

License
====

Apache 2.0.  Please see the LICENSE file for more information.

EOF

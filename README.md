Puppet WebHooks
====

[![Build Status](https://travis-ci.org/puppetlabs/puppet-webhooks.png?branch=master)](https://travis-ci.org/puppetlabs/puppet-webhooks)

This project performs a job or jobs when a pull request event occurs on
[Github](https://github.com/).  Current implemented behaviors are:

 * [✓] Create a Trello Card when a Pull Request is created or synchronized.
 * [✓] Avoid duplicate cards being created when a pull request is synchronized or closed.
 * [✓] Check the `X-Hub-Signature` created by the [web service hook][web-service-hook].
 * [✓] Queue work and perform jobs asynchronously.
 * [✓] Auto-scale the number of workers to zero when there are no jobs to perform.
 * [✓] Auto-scale the number of workers to one when there are jobs to perform.
 * [✓] Near real-time behavior, no polling intervals involved.
 * [ ] Archive a Trello Card when a Pull Request is closed.
 * [ ] Check multiple boards for the existence of a card.
 * [ ] Copy a comment to the card when a comment is added to the pull request.

[web-service-hook]: https://github.com/github/github-services/blob/master/services/web.rb

Quick Start
====

First, review the [Heroku Quickstart][quickstart] guide.  Next, we simply need
to create a copy of this application.  run `heroku create` which will add a git
remote named `heroku` to the git repository.  Deployments will happen with a
simple `git push heroku`.

Here's what the first step, `heroku create` looks like.  An application name
and URL will automatically be chosen for you.  The application name may be
changed in the [Heroku Dashboard][dashboard].

    $ heroku create
    Creating fierce-meadow-9708... done, stack is cedar
    http://fierce-meadow-9708.herokuapp.com/ | git@heroku.com:fierce-meadow-9708.git
    Git remote heroku added

Next, push the application to [Heroku][heroku] with `git push heroku HEAD:master`.

    $ git push heroku HEAD:master
    Counting objects: 195, done.
    Delta compression using up to 8 threads.
    Compressing objects: 100% (176/176), done.
    Writing objects: 100% (195/195), 46.71 KiB, done.
    Total 195 (delta 83), reused 7 (delta 1)
    -----> Ruby/Rack app detected
    -----> Installing dependencies using Bundler version 1.3.0.pre.2
           Running: bundle install --without development:test --path vendor/bundle --binstubs bin/ --deployment
           Fetching gem metadata from http://rubygems.org/.......
           Fetching gem metadata from http://rubygems.org/..
           Installing rake (10.0.3)
           Installing i18n (0.6.1)
           ...
           Installing workless (1.1.1)
           Your bundle is complete! It was installed into ./vendor/bundle
           ...
           Cleaning up the bundler cache.
    -----> Writing config/database.yml to read from DATABASE_URL
    -----> Discovering process types
           Procfile declares types     -> web, worker
           Default types for Ruby/Rack -> console, rake
    -----> Compiled slug size: 6.8MB
    -----> Launching... done, v6
           http://fierce-meadow-9708.herokuapp.com deployed to Heroku
    To git@heroku.com:fierce-meadow-9708.git
     * [new branch]      HEAD -> master

Database Migration
----

Once the application is pushed, the database schema needs to be created.  This
is accomplished using a migration rake task:

    $ heroku run bundle exec rake db:migrate
    Running `bundle exec rake db:migrate` attached to terminal... up, run.9637
       (1209.8ms)  CREATE TABLE "schema_migrations" ("version" character varying(255) NOT NULL)
       (28.7ms)  CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version")
       (0.8ms)  SELECT "schema_migrations"."version" FROM "schema_migrations"
    Migrating to CreateDelayedJobs (1)
       (0.9ms)  BEGIN
    ==  CreateDelayedJobs: migrating ==============================================
    -- create_table(:delayed_jobs, {:force=>true})
    NOTICE:  CREATE TABLE will create implicit sequence "delayed_jobs_id_seq" for serial column "delayed_jobs.id"
    NOTICE:  CREATE TABLE / PRIMARY KEY will create implicit index "delayed_jobs_pkey" for table "delayed_jobs"
       (168.8ms)  CREATE TABLE "delayed_jobs" ("id" serial primary key, "priority" integer DEFAULT 0, "attempts" integer DEFAULT 0, "handler" text, "last_error" text, "run_at" timestamp, "locked_at" timestamp, "failed_at" timestamp, "locked_by" character varying(255), "queue" character varying(255), "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL)
       -> 0.1997s
    -- add_index(:delayed_jobs, [:priority, :run_at], {:name=>"delayed_jobs_priority"})
       (5.3ms)  CREATE INDEX "delayed_jobs_priority" ON "delayed_jobs" ("priority", "run_at")
       -> 0.0075s
    ==  CreateDelayedJobs: migrated (0.2074s) =====================================
       (1.0ms)  INSERT INTO "schema_migrations" ("version") VALUES ('1')
       (4.8ms)  COMMIT

Finally, set the configuration variables that contain the Trello API keys and
Github shared secret.  First, the shared secret so we can authenticate Github
requests:

Github Shared Secret
----

In order to provide some authentication of the request a secret key may be
configured in GitHub and in Heroku.  This shared secret key may then be used to
validate a digital signature of the body of the request in the
`X-Hub-Signature` header.  Validating the signature should just be a matter of
comparing the value of the header with the computed value.

See [web service hook][web-service-hook] for more information.  To configure
the secret, make sure the `secret` key in the `config` hash posted to
`https://api.github.com/repos/<account>/<repository>/hooks` matches the
`GITHUB_X_HUB_SIGNATURE_SECRET` configuration setting in Heroku.

To set these from the shell:

    url="https://fierce-meadow-9708.herokuapp.com/event/pull_request"
    secret="$(dd if=/dev/random bs=1k count=1 | openssl sha256 | awk '{print $2}')"

Then configure this hook URL and shared secret on Github:

    curl -i -u jeffmccune -d '
    {
      "name": "web",
      "active": true,
      "events": ["pull_request"],
      "config": {
        "url": "'"${url}"'",
        "secret": "'"${secret}"'",
        "content_type": "json"
      }
    }' https://api.github.com/repos/puppetlabs/puppet/hooks

And finally the setting in heroku:

    heroku config:set GITHUB_X_HUB_SIGNATURE_SECRET="$secret"

Trello OAuth Tokens
----

Four configuration settings determine how to authenticate against Trello and
where to place cards.  These four settings are:

    TRELLO_APP_KEY=b8315fbed85ee3c20c41b58b4ad7b73a
    TRELLO_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    TRELLO_USER_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    TRELLO_TARGET_LIST_ID=50bd46a84c27cb74100036be

These are settable using the heroku command line interface:

    heroku config:add  \
      TRELLO_APP_KEY=b8315fbed85ee3c20c41b58b4ad7b73a \
      TRELLO_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
      TRELLO_USER_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
      TRELLO_TARGET_LIST_ID=50bd46a84c27cb74100036be

The Trello app key and secret can be retrieved from
[https://trello.com/1/appKey/generate](https://trello.com/1/appKey/generate).

The Trello user token can be generated with various expiration dates and
permissions via instructions at
[https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user](https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)

The Trello list ID where the cards should be created.  To find this value,
navigate to the Trello board that you are interested in in your browser and
copy the board id from the URL.  Then run the
[show_lists_for_board.rb](https://github.com/cprice-puppet/redmine-trello/blob/master/bin/show_lists_for_board.rb)
command line tool against that board id, and you'll see a list of available
List Ids for that board.

Delayed Job
----

Talking to the various API endpoints are a bit more time consuming than the
500ms web dyno recommended response time.  To make sure the web dyno is nice
and responsive, delayed job worker dynos are used to perform the heavy lifting.

Delayed job requires an SQL database.  Most of the documentation assumes Rails,
but we're taking the Sinatra only approach.  Heroku should automatically detect
the 'pg' gem is in use and will should have provisioned a database
automatically.  If not, please add the database using the following
information.

Workless
----

To use [workless][workless] the Heroku API key is required.  This is obtainable
using the following commands.  (TODO Make this a rake task).  The API key is
the password field of `~/.netrc` for the host api.heroku.com.

    heroku config:add \
      HEROKU_API_KEY=$HEROKU_API_KEY \
      APP_NAME=fierce-meadow-9708

PostgreSQL Database
----

To configure an SQL database: (More detailed information at [heroku
postgresql][heroku-postgresql].)

    heroku addons:add heroku-postgresql:dev
    Adding heroku-postgresql:dev on fierce-meadow-9708... done, v23 (free)
    Attached as HEROKU_POSTGRESQL_GREEN_URL
    Database has been created and is available
     ! This database is empty. If upgrading, you can transfer
     ! data from another database with pgbackups:restore.
    Use `heroku addons:docs heroku-postgresql:dev` to view documentation.

Then promote this database to be the provisioned database.  You may need to
replace `GREEN` with the color assigned by Heroku shown in the output of the
above command.

    heroku pg:promote HEROKU_POSTGRESQL_GREEN_URL
    Promoting HEROKU_POSTGRESQL_GREEN_URL to DATABASE_URL... done

If developing locally, the database configuration should be stored in
`config/database.yml`.  Heroku will automatically replace this file according
to [Ruby Support Build behavior][BuildBehavior].  (Note, in Heroku the
database.yml file needs to be fed through ERB.  It is not valid YAML if read
directly.)

[workless]: https://github.com/lostboy/workless
[heroku-postgresql]: https://devcenter.heroku.com/articles/heroku-postgresql
[BuildBehavior]: https://devcenter.heroku.com/articles/ruby-support#build-behavior

GitHub Setup
----

The WebHook URL's in a repository's admin interface only fire with branches are
pushed.  The API must be used to trigger generic WebHooks for other events.

See:

 * [Repo Hooks API](http://developer.github.com/v3/repos/hooks/)
 * [Add a github repo webhook for pull
   requests](https://gist.github.com/2726012)
 * [github-services
   web.rb](https://github.com/github/github-services/blob/master/services/web.rb)
 * [github OAuth token for command line
   use](https://help.github.com/articles/creating-an-oauth-token-for-command-line-use)
   (Our app will use this token to interact with github)
 * [github scopes](http://developer.github.com/v3/oauth/#scopes)

Check the current hooks:

    curl -i -u jeffmccune https://api.github.com/repos/jeffmccune/puppet-webhooks/hooks

Listing Jobs
----

If you're curious to see how jobs are getting queued, start up a server
locally, then submit some fake pull requests using the rake tasks:

    $ rake api:run
    foreman start
    18:19:13 web.1  | started with pid 60414

Then, in another terminal, submit a fake pull request webhook just as Github
will:

    $ rake api:pull_request
    curl -i --data "payload=$(cat spec/unit/fixtures/example_pull_request.json)" http://localhost:5000/event/pull_request
    HTTP/1.1 200 OK
    Content-Type: text/html;charset=utf-8
    Content-Length: 0
    Connection: keep-alive
    Server: thin 1.5.0 codename Knife

You should now see this job in your PostgreSQL database:

    jeff=# \c "puppet_webhooks_dev"
    You are now connected to database "puppet_webhooks_dev" as user "jeff".
    puppet_webhooks_dev=# select id,last_error,run_at,queue from delayed_jobs;
     id | last_error |           run_at           |    queue
    ----+------------+----------------------------+--------------
      6 |            | 2012-12-30 18:22:10.964711 | pull_request
    (1 row)

This job will be cleared when you run `rake jobs:work`.

Authentication
----

Incoming requests may be authentication against Github and Travis.  Travis uses
the pattern `#{username}/#{repository}#{TRAVIS_AUTH_TOKEN}`.

Configuring Github requires the same configuration as the deployment.  This is
currently `gepetto-bot`.

Get the specific URL of the travis hook by listing all of the hooks:

    $ curl -i -u "jeffmccune:$PASSWORD" \
    https://api.github.com/repos/jeffmccune/puppet-webhooks/hooks | tee hooks.json

With the specific hook URL:

    $ curl -i -u "jeffmccune:$PASSWORD" -d '
    {  "config": {
         "token": "'"$TRAVIS_AUTH_TOKEN"'",
         "user": "gepetto-bot",
         "domain": ""
      }
    }' https://api.github.com/repos/jeffmccune/puppet-webhooks/hooks/633908

Maintainer
----

Jeff McCune <jeff@puppetlabs.com>

[heroku]: https://www.heroku.com
[dashboard]: https://dashboard.heroku.com/apps
[quickstart]: https://devcenter.heroku.com/articles/quickstart

EOF

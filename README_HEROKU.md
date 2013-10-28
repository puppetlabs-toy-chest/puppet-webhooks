puppet-webhooks in Heroku
===

Quick Start
---

First, review the [Heroku Quickstart][quickstart] guide. Create an account and
install the Toolbelt. To use this code on Heroku you'll need to verify your
account by adding a valid credit card, even if you use the free facilities.
Without this verification you will receive an error within Heroku when
receiving notifications.  The code may be run without a credit card using
`RACK_ENV=development foreman start` with a local PostgreSQL server.

The rest of this section is concerned with deploying the application to Heroku.

Next, we simply need to create a copy of this application.  run `heroku create`
which will add a git remote named `heroku` to the git repository.  Deployments
will happen with a simple `git push heroku`.

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

### Configuration Options

The application is up and running at this point, but the following
configuration options may be useful.  All of the configuration of this
application is done using environment variables set through the `heroku
config:add` action.

For the specific configuration needed, please review the documentation in the
READMEs for Github, Trello, and Jira.


### PostgreSQL Database

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

### Database Migration

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

Delayed Job
----

Talking to the various API endpoints are a bit more time consuming than the
500ms web dyno recommended response time.  To make sure the web dyno is nice
and responsive, delayed job worker dynos are used to perform the heavy lifting.

Delayed job requires an SQL database.  Most of the documentation assumes Rails,
but we're taking the Sinatra only approach.  Heroku should automatically detect
the 'pg' gem is in use and will should have provisioned a database
automatically.  This can be checked with `heroku pg:info`.  If not, please add
the database using the following information.

### Listing Jobs

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


Workless
----

To use [workless][workless] the Heroku API key is required.  This is obtainable
using the following commands.  (TODO Make this a rake task).  The API key is
the password field of `~/.netrc` for the host api.heroku.com.

    heroku config:add \
      HEROKU_API_KEY=$HEROKU_API_KEY \
      APP_NAME=fierce-meadow-9708

[workless]: https://github.com/lostboy/workless
[heroku-postgresql]: https://devcenter.heroku.com/articles/heroku-postgresql
[BuildBehavior]: https://devcenter.heroku.com/articles/ruby-support#build-behavior


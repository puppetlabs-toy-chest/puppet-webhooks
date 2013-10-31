puppet-webhooks in Heroku
===

Quick Start
---

The quickstart guide for puppet-webhooks is available at HEROKU_QUICKSTART.md.

Components
----------

### PostgreSQL

puppet-webhooks requires a database to store Jira project configuration,
delayed jobs, and store incoming events. PostgreSQL is the supported database
for Heroku instances.

[heroku-postgresql]: https://devcenter.heroku.com/articles/heroku-postgresql

To configure an SQL database: (More detailed information at [heroku
postgresql][heroku-postgresql].)

    heroku addons:add heroku-postgresql:dev
    Adding heroku-postgresql:dev on fierce-meadow-9708... done, v23 (free)
    Attached as HEROKU_POSTGRESQL_GREEN_URL
    Database has been created and is available
     ! This database is empty. If upgrading, you can transfer
     ! data from another database with pgbackups:restore.
    Use `heroku addons:docs heroku-postgresql:dev` to view documentation.

[BuildBehavior]: https://devcenter.heroku.com/articles/ruby-support#build-behavior

If developing locally, the database configuration should be stored in
`config/database.yml`.  Heroku will automatically replace this file according
to [Ruby Support Build behavior][BuildBehavior].  (Note, in Heroku the
database.yml file needs to be fed through ERB.  It is not valid YAML if read
directly.)

### Delayed Job
----

Talking to the various API endpoints are a bit more time consuming than the
500ms web dyno recommended response time.  To make sure the web dyno is nice
and responsive, delayed job worker dynos are used to perform the heavy lifting.

Workless
----

[workless]: https://github.com/lostboy/workless

Since running a persistent delayed_job worker can needlessly consume CPU time,
workless is used to run delayed jobs on demand.

**IMPORTANT**: To use [workless][workless], the Heroku API key and Heroku app
name are _required_. This is obtainable using the following commands.

    heroku config:set \
      HEROKU_API_KEY=your-heroku-api-key \
      APP_NAME=puppet-webhooks

### Debugging

The following error indicates that the Heroku API key is either unset or
incorrect:

    #<Heroku::API::Errors::Unauthorized: Expected(200) <=> Actual(401 Unauthorized)>

The following error indicates that the Heroku app name is either unset or
incorrect:

    #<Heroku::API::Errors::NilApp: Expected(200) <=> Actual(404 Not Found)>

[heroku-auth]: https://devcenter.heroku.com/articles/authentication

More information on Heroku API keys is available on the [Heroku authentication
article][heroku-auth].

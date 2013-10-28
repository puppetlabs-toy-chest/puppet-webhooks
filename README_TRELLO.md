puppet-webhooks Trello integration
===

puppet-webhooks supports Trello as an event destination

Trello OAuth Tokens
----

Four configuration settings determine how to authenticate against Trello and
where to place cards.  These four settings are:

    TRELLO_APP_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    TRELLO_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    TRELLO_USER_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    TRELLO_TARGET_LIST_ID=50bd46a84c27cb74100036be

These are settable using the heroku command line interface:

    heroku config:add  \
      TRELLO_APP_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
      TRELLO_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
      TRELLO_USER_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
      TRELLO_TARGET_LIST_ID=50bd46a84c27cb74100036be

The Trello app key and secret can be retrieved from
[https://trello.com/1/appKey/generate](https://trello.com/1/appKey/generate).

The Trello user token can be generated with various expiration dates and
permissions via instructions at
[https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user](https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user).
For this application to create and update Trello cards, you must supply a token
with read and write access.

The Trello list ID where the cards should be created.  To find this value,
navigate to the Trello board that you are interested in in your browser and
copy the board id from the URL, then run:

    $ curl "https://api.trello.com/1/board/<board_id>/lists?key=<app_key>&token=<user_token>"
    [{"id":"xxxxxxxxxxxxxxxxx","name":"Pull Requests","closed":false,"idBoard":"xxxxxxxxxxxxxxxxxx","pos":8192,"subscribed":false}]

And copy the id for the list where you want new cards to be created.

Due Dates and Timezones
----

Add a due date for newly created cards if you have a target response time for
pull requests you'd like to track.  At Puppet Labs we use this as a clear way
to stay on top of incoming pull requests.  If this variable is `"true"` then
the application will set the due date of a newly created cards to 2 PM of the
next business day.  Please note this behavior depends on the timezone.

    $ heroku config:set TRELLO_SET_TARGET_RESPONSE_TIME=true
    $ heroku config:set TZ=America/Los_Angeles

A list of timezone strings may be found at [List of tz database time
zones](http://en.wikipedia.org/wiki/List_of_tz_database_time_zones)


Multiple Boards
----

Often times a card will move from one board to another board if there are
multiple teams working together.  If a card is not located on the board
containing the target list for newly created cards, then the application will
not find the already created card by default.  The app may be configured to
search for a card on additional boards if the card is not found on the board
containing the target list.  To do so, set the `TRELLO_BOARDS` variable to a
comma separated list of board identifiers.  (Note, the board ID may be copied
directly from the Trello URL)

    $ heroku config:set TRELLO_BOARDS=4fd8ed1769c9e77f1e0d6882,50bd46a84c27cb74100035f5

Finished Card Summary
----

A summary of finished cards may be produced using the `jobs:summary` rake task.
This allows a summary document of work completed to be automatically generated.

##### Configuration

Use the github machine account to create a private gist and create a file named
`SUMMARY.md`.  For example, https://gist.github.com/gepetto-bot/5166341.
Configure the gist id using the `GITHUB_SUMMARY_GIST_ID` environment variable.

    $ heroku config:set GITHUB_SUMMARY_GIST_ID=5166341 --app fast-reef-2454

Configure the finished list id to scan finished cards from.  The app will scan
card comments for a comment with a prefix of `summary:` and use this as the
message for the card.  The app will scan the card labels for label names
matching `status:` and group cards by these labels.  For example, `Status: Not
Merged`, and `Status: Merged`.

    $ heroku config:set TRELLO_FINISHED_LIST_ID=50bd46a84c27cb74100036c5 --app fast-reef-2454

With these configuration variables set, test running the rake task works using
`heroku run`.  If it does, then it should work using the heroku scheduler
addon.

    $ heroku run bundle exec rake jobs:summary --app fast-reef-2454
    Running `bundle exec rake jobs:summary` attached to terminal... up, run.1334
    Summarizing completed cards...
    publish_summary_time_seconds=0.3944990634918213
    summary_time_seconds=3.4219908714294434
    gist_url=https://gist.github.com/5166341

Finally, configure the scheduler to execute the job once per day.

    $ heroku addons:add scheduler:standard --app fast-reef-2454
    Adding scheduler:standard on fast-reef-2454... done
    $ heroku addons:open scheduler --app fast-reef-2454
    Opening scheduler:standard for fast-reef-2454... done

Then add the following command to execute daily at 23:00 UTC:

    bundle exec rake jobs:summary

The template used to produce the summary may be configured using the
`SUMMARY_TEMPLATE_URL` environment variable.  For example:

    bundle exec rake jobs:summary SUMMARY_TEMPLATE_URL=https://raw.github.com/puppetlabs/puppet-webhooks/templates/templates/trello_template.md.liquid

The default template is located at
[trello_template.md.liquid](https://github.com/puppetlabs/puppet-webhooks/blob/templates/templates/trello_template.md.liquid).


Puppet WebHooks
====

This project responds to activity on GitHub.  Current features are:

 * [✓] Say "Hello World" from Sinatra [Try it](http://puppet-dev-community.herokuapp.com/)
 * [✓] Create a staging service [Try it](http://puppet-dev-community-staging.herokuapp.com/)
 * [✓] Process the GitHub payload.
   [Endpoint](http://puppet-dev-community-staging.herokuapp.com/trello/puppet-dev-community)
   and the [Endpoint
   Viewer](http://puppet-dev-community-staging.herokuapp.com/trello/puppet-dev-community/view)
 * [✓] Create a Trello Card when a Pull Request is created or synchronized.
 * [ ] Avoid duplicate cards being created when a pull request is synchronized or closed.
 * [ ] Copy a comment to the card when a comment is added to the pull request.
 * [ ] Move a Trello Card when a Pull Request is closed.

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
      TRELLO_TARGET_LIST_ID=50bd46a84c27cb74100036be \
      --app puppet-dev-community-staging

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

Configure the staging hook:

    url="http://puppet-dev-community-staging.herokuapp.com/trello/puppet-dev-community"
    curl -i -u jeffmccune -d '
    {
      "name": "web",
      "active": true,
      "events": ["pull_request"],
      "config": {
        "url": "'"${url}"'"
      }
    }' https://api.github.com/repos/jeffmccune/puppet-webhooks/hooks

This command should return a result like the following:

    HTTP/1.1 201 Created
    Server: nginx
    Date: Thu, 06 Dec 2012 07:41:53 GMT
    Content-Type: application/json; charset=utf-8
    Connection: keep-alive
    Status: 201 Created
    Content-Length: 542
    ETag: "d3a6272949e5dd612f7705f9ee1cf02f"
    X-GitHub-Media-Type: github.beta
    X-RateLimit-Limit: 5000
    X-RateLimit-Remaining: 3461
    Location: https://api.github.com/repos/jeffmccune/puppet-webhooks/hooks/582457
    Cache-Control: max-age=0, private, must-revalidate
    X-Content-Type-Options: nosniff
    
    {
      "last_response": {
        "status": "unused",
        "code": null,
        "message": null
      },
      "events": [
        "pull_request"
      ],
      "url": "https://api.github.com/repos/jeffmccune/puppet-webhooks/hooks/582457",
      "updated_at": "2012-12-06T07:41:53Z",
      "name": "web",
      "created_at": "2012-12-06T07:41:53Z",
      "config": {
        "url": "http://puppet-dev-community-staging.herokuapp.com/trello/puppet-dev-community"
      },
      "active": true,
      "id": 582457,
      "test_url": "https://api.github.com/repos/jeffmccune/puppet-webhooks/hooks/582457/test"
    }

And now, opening a new pull request should cause the file 'buffer' to be
written and the view URI will return it.

Maintainer
----

Jeff McCune <jeff@puppetlabs.com>

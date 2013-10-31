Deploy Quick start
---

You will need a Heroku account to follow this quick start guide.

### Walkthrough

This is a quick walkthrough of the steps needed to get everything running. For
more information, consult the application specific README.

#### Create a new heroku app:

    $ heroku apps:create puppet-webhooks-demo --remote heroku-demo --region us
    Creating puppet-webhooks-demo... done, region is us
    http://puppet-webhooks-demo.herokuapp.com/ | git@heroku.com:puppet-webhooks-demo.git

#### Deploy the puppet-webhooks application (output tuncated for brevity):

    $ git push heroku-demo HEAD:master

    Counting objects: 2165, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (1670/1670), done.
    Writing objects: 100% (2165/2165), 343.02 KiB | 537.00 KiB/s, done.
    Total 2165 (delta 1334), reused 868 (delta 447)

    -----> Ruby/Rails app detected
    -----> Using Ruby version: ruby-2.0.0
    [...]
    -----> Compiled slug size: 32.4MB
    -----> Launching... done, v5
           http://puppet-webhooks-demo.herokuapp.com deployed to Heroku

    To git@heroku.com:puppet-webhooks-demo.git
     * [new branch]      HEAD -> master

#### Create a PostgreSQL DB instance:

    $ heroku addons:add heroku-postgresql:dev
    Adding heroku-postgresql:dev on puppet-webhooks-demo... done, v6 (free)
    Attached as HEROKU_POSTGRESQL_WHITE_URL
    Database has been created and is available
    Use `heroku addons:docs heroku-postgresql:dev` to view documentation.

#### Prepare the DB schema:

    $ heroku run rake db:migrate
    Running `rake db:migrate` attached to terminal... up, run.5326
    ==  CreateDelayedJobs: migrating ==============================================
    [...]
    Migrating to CreateDelayedJobs (1)
    Migrating to CreateEvents (20130114031521)

#### Add the Heroku API token for workless

    $ heroku config:set \
      HEROKU_API_KEY=your-heroku-api-key \
      APP_NAME=puppet-webhooks

#### Set up Github webhook handlers and shared secret

##### Configure Heroku with the shared secret

    $ bin/github-gen-secret
    54eac79fdea8fa16458f5b7c5ca757748143008c043ed7dce9b8b1deae92270d
    # Hang on to this; you'll need it for the Github webhooks and the
    # heroku configuration
    $ heroku config:set --app puppet-webhooks-demo GITHUB_X_HUB_SIGNATURE_SECRET=54eac79fdea8fa16458f5b7c5ca757748143008c043ed7dce9b8b1deae92270d
    Setting config vars and restarting puppet-webhooks-demo... done, v7

##### Create the github webhook handler with a shared secret

    $ bin/github-template-hook hook-template.json
    [...]
    $ vim hook-template.json
    # Configure the hook template to your needs
    $ bin/github-new-hook adrienthebo puppetlabs puppet hook-template.json
    Enter host password for user 'adrienthebo':
    HTTP/1.1 201 Created

#### Configure Github credentials (required)

    # Only list the outputs you want to use
    $ heroku config:set GITHUB_EVENT_OUTPUTS="jira,trello"
    $ heroku config:set \
      GITHUB_ACCOUNT=gepetto-bot \
      GITHUB_TOKEN=oauth_token_here

#### Configure Trello settings (optional)

    $ heroku config:set \
      TRELLO_APP_KEY=user_oauth_key \
      TRELLO_BOARDS=list,of,board,ids \
      TRELLO_FINISHED_LIST_ID=trello_list_id \
      TRELLO_SECRET=trello_oauth_secret \
      TRELLO_TARGET_LIST_ID=list_to_add_new_cards \
      TRELLO_USER_TOKEN=user_oauth_token

#### Configure Jira settings (optional)

    $ heroku config:set \
      JIRA_USERNAME=user-name \
      JIRA_PASSWORD=user-password \
      JIRA_SITE=http://jira.server \
      JIRA_CONTEXT_PATH=/path/to/jira \
      JIRA_USE_SSL=true

##### Set up per-project configuration

    $ heroku run thor projects:create puppetlabs/puppet PP --jira_components=github


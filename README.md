Puppet WebHooks
====

This project responds to activity on GitHub.  Current features are:

 * [✓] Say "Hello World" from Sinatra [Try it](http://puppet-dev-community.herokuapp.com/)
 * [✓] Create a staging service [Try it](http://puppet-dev-community-staging.herokuapp.com/)
 * [✓] Process the GitHub payload.
   [Endpoint](http://puppet-dev-community-staging.herokuapp.com/trello/puppet-dev-community)
   and the [Endpoint
   Viewer](http://puppet-dev-community-staging.herokuapp.com/trello/puppet-dev-community/view)
 * [ ] Create a Trello Card when a Pull Request is created or synchronized.
 * [ ] Move a Trello Card when a Pull Request is closed.

GitHub Setup
----

The WebHook URL's in a repository's admin interface only fire with branches are
pushed.  The API must be used to trigger generic WebHooks for other events.

See:

 * [Repo Hooks API](http://developer.github.com/v3/repos/hooks/)
 * [The way I had to add a github repo webhook for pull requests](https://gist.github.com/2726012)
 * [github-services web.rb](https://github.com/github/github-services/blob/master/services/web.rb)

Maintainer
----

Jeff McCune <jeff@puppetlabs.com>

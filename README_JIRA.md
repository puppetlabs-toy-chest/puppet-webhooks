puppet-webhooks Jira integration
================================

Environment variables
---------------------

For puppet-webhooks to be able to create Jira issues, the following environment
variables need to be specified.

### JIRA_SITE and JIRA_CONTEXT_PATH

The hostname and URL path for the Jira instance need to be specified so that
puppet-webhooks can create and update issues. The JIRA_SITE variable should be
set to the hostname and port of the Jira server, and the JIRA_CONTEXT_PATH
should be the URL path to the Jira instance root.

#### Examples

##### https://webserver.example.com/path/to/jira

    JIRA_SITE=https://webserver.example.com
    JIRA_CONTEXT_PATH=/path/to/jira

##### https://jira.example.com

    JIRA_SITE=https://jira.example.com
    JIRA_CONTEXT_PATH=''

### JIRA_USERNAME and JIRA_PASSWORD

A Jira user and the password for that user need to be specified to create
issues.

### JIRA_USE_SSL

By default, connections to Jira are done over SSL. To disable, this, set the
`JIRA_USE_SSL` environment variable to false.

Project configuration
---------------------

Different github repositories can be configured to create issues in different
Jira projects with different labels and components:

### Examples

#### Create a single project with no labels or components

    thor projects:create puppetlabs/puppet-webhooks PW

#### Create a single project with labels and components

    thor projects:create puppetlabs/puppet-webhooks PP --jira_labels webhooks github --jira_components tooling

#### Create a two Github projects going to the same Jira project

    thor projects:create puppetlabs/puppetdb PDB --jira_labels github
    thor projects:create puppetlabs/puppetlabs-puppetdb PDB --jira_labels github module

#### List projects

    thor projects:list

#### Delete a project

    thor projects:delete puppetlabs/puppet-webhooks
---

Github events coming from a project that is not explicitly configured will be
ignored.

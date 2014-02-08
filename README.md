# Atlassian CLI

This program is an easy-to-use, scriptable API for interacting with JIRA (and
eventually other Atlassian products) via the REST API.

Whenever possible, this CLI will implement a "pure JSON" option for input and
output, allowing maximum machine-parsability.  RecordStream is a huge potential
candidate for using with the atlas-cli.

# Usage

## SYNOPSIS

    atlas-jira-cli --help # for full help page

    atlas-jira-cli jql "assignee = someuser and project = QA and created > -1d"
    atlas-jira-cli view QA-1234
    atlas-jira-cli transition QA-1234 --editState close
    atlas-jira-cli edit QA-1234 --fix-versions='+1.1.1' --fix-versions='-1.1.0' --comment "bumping to a later release"
    atlas-jira-cli comment QA-1234 --comment "This is harder than I thought!"
    atlas-jira-cli create --project-key QA --summary "File all the tickets!" \
            --description "Meme of the year, amirite?" \
            --priority p1 \
            --components regression \
            --affects-versions 1.0.0 \
            --affects-versions 1.1.0 \
            --fix-versions 1.1.1

# Setting up with RVM

Since atlassian-cli requries a custom version of the terminal-table gem, it must always be executed with `bundle exec`.

To set this up, it is advised you do the following:

    rvm use ruby-2.0.0@atlascli --create
    bundle install
    # create a bash script in your path, obviously adjust the paths to point to
    # your rvm directory and your checkout of atlassian-cli

    #!/bin/bash
    ATLAS_CLI_DIR=/home/$USER/gitrepos/atlassian-cli
    RVM_DIR=/home/$USER/.rvm
    GEMSET=ruby-2.0.0-p195@atlascli
    cd $ATLAS_CLI_DIR && $RVM_DIR/bin/$GEMSET -S bundle exec $ATLAS_CLI_DIR/bin/atlas-jira-cli "$@"

# Authentication

Initially, the script will prompt for a username and a password.  If you don't
want to type it in every time you can store credentials in your ~/.netrc file
using the standard format (see `man netrc` for details).

# DEV GUIDE

To run an instance of jira for testing using the atlassian plugin sdk

    atlas-run-standalone --server localhost --product jira --version 5.2.11

Note that you have to create the project and some issues first... intial db is empty.

To hit an endpoint using curl, for example:

    curl --user admin:admin 'http://localhost:2990/jira/rest/api/2/search?jql=project%3Dfoo'

# TODO
There are many things I'd eventually like to implement.  For now, they are
broken up by product.

## BUGS
* Create new issue with no component/type, try to edit it, profit?

## JIRA
* Create Components
* Support converting regular issues to sub-tasks (blocked by https://jira.atlassian.com/browse/JRA-27893)
* Move issue (also not supported by the rest API: https://answers.atlassian.com/questions/132846/how-move-issue-to-another-project-via-rest-api)
* JQL Query Pagination
* list components, priorities, assignees, etc.
* issue labels
* Selectively get only fields we need (PERF)
* Clean up regex based things (allow exact match, --dry-run, specify by ID, etc)
* Extract more hashifiers (for comments, etc) for better code reuse
* A way to query required fields

## Confluence
* Fetch raw page, upload raw page
* vim/emacs integration

## Stash
* Search for projects/repositories
* Search for pull requests
* Create pull request
* Permissions admin?

## Generic
* Support using a session cookie to cache credentials (p0, otherwise the CLI puts undue load on crowd/ldap)
* TEST COVERAGE
* Implement oauth support?
* Support mac OSX keychain?

## Bamboo
* Search / list builds
* Trigger builds
* Fetch artifacts / logs

## Crowd
* Test auth credentials
* Administration?

## Fisheye
* lol, jk


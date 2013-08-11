# Atlassian CLI

This program is an easy-to-use, scriptable API for interacting with JIRA (and
eventually other Atlassian products) via the REST API.

Whenever possible, this CLI will implement a "pure JSON" option for input and
output, allowing maximum machine-parsability.  RecordStream is a huge potential
candidate for using with the atlas-cli.

# Usage

# using rvm...
rvm use ruby-2.0.0@atlascli --create
bundle install
bundle exec bin/atlas-jira-cli <args>

# Authentication

TODO

# DEV GUIDE

To run an instance of jira for testing using the atlassian plugin sdk

    atlas-run-standalone --server localhost --product jira --version 5.2.11

Note that you have to create the project and some issues first... intial db is empty.

To hit an endpoint using curl, for example:

    curl --user admin:admin 'http://localhost:2990/jira/rest/api/2/search?jql=project%3Dfoo'

# TODO
There are many things I'd eventually like to implement.  For now, they are
broken up by product.

## JIRA
* JQL Query Pagination
* Attach files

## Confluence
* Fetch raw page, upload raw page
* vim/emacs integration

## Stash
* Search for projects/repositories
* Search for pull requests
* Create pull request
* Permissions admin?

## Generic
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


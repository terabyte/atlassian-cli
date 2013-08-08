# Atlassian CLI

This program is an easy-to-use, scriptable API for interacting with JIRA (and
eventually other Atlassian products) via the REST API.

Whenever possible, this CLI will implement a "pure JSON" option for input and
output, allowing maximum machine-parsability.  RecordStream is a huge potential
candidate for using with the atlas-cli.

# Usage

TODO

# Authentication

TODO

# setting up ssh-agent
TODO

# TODO
There are many things I'd eventually like to implement.  For now, they are
broken up by product.

* Implement oauth support?
* Support mac OSX keychain?

## JIRA
* JQL Query
* View issue by certain fields / comments
* Comment on issues
* Create issues
* Transition issue state
* Attach files

## Stash
* Search for projects/repositories
* Search for pull requests
* Create pull request
* Permissions admin?

## Confluence
* Fetch raw page, upload raw page
* vim/emacs integration

## Bamboo
* Search / list builds
* Trigger builds
* Fetch artifacts / logs

## Crowd
* Test auth credentials
* Administration?

## Fisheye
* lol, jk


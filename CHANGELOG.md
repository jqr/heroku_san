# Change log (curated)

## v2.1.4

  * Use heroku-api for client calls instead heroku gem

## v2.1.3

  * Bug fixes

## v2.1.2

  * Bug fixes
  * 1.8.7 backward compatibility
  * Refactoring

## v2.1.1

  * Bug fixes
  * Changed most Stage methods to call Heroku::Client methods instead of shelling out
  * Finished integration tests

## v2.1.0

  * Documentation update
  * Push `REVISION` to Heroku example
  * Bug fixes

### New tasks

  * rake logs:tail
  * rake shell
  * All HerokuSan tasks inside heroku: namespace, with aliases in the global namespace

### New methods

  * `Stage#deploy`
  * `Stage#maintenance` can now take a block, and ensures that maintenance mode is off afterwards.
  * `Stage#push_config`
  
## v2.0.0

  * Major rewrite into classes `Project` & `Stage`, with helper `Git` module
  * Tests for _everything_
  * Examples directory (e.g. `auto-tagger`)
  * Removed dependencies on Rails
  * `tasks.rb` is greatly simplified, mostly API calls into the `Stage` class
  * Support for tagging releases and deploying apps using a tag glob
  * Support for Heroku stacks (aspen, bamboo & cedar)

## v1.3.0

N/A
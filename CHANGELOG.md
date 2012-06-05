# Change log (curated)

## v3.0.3

  * Use Heroku's db:pull instead of PGBackups
  
## v3.0.2

  * Fix config:list bug (#90)

## v3.0.1

  * Fix deploy:force bugs (#84 & #85)

## v3.0.0

  * New feature: support for Rack apps (e.g. Sinatra)
  * Removes dependency on Rails
  * New feature: deploy strategy class for customizing the :deploy target
  * `Stage#deploy` calls strategy (breaks v2 API)
  * `Stage#push` pushes to Heroku
  * If you have a Rails app, you don't have to do anything; the gem will
    automatically configure itself to use the Rails deploy strategy. See
    the README for how to configure you Rack app's `Rakefile`
  
## v2.2.1

  * New feature: addons from [Matt Burke](https://github.com/spraints)

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
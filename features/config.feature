Feature: Command Line

  Background:
    Given I run `rails new heroku_san_test --quiet --force --skip-active-record --skip-bundle --skip-javascript --skip-test-unit --skip-sprockets`
    And I cd to "heroku_san_test"
    And I overwrite "Gemfile" with:
      """
      source :rubygems
      gem 'rails'
      gem 'heroku_san', :path => '../../../.'
      """

  Scenario: Config file can be formatted like Rails' database.yml
    Given a file named "config/heroku.yml" with:
      """
      production: 
        app: awesomeapp
      staging:
        app: awesomeapp-staging
      demo: 
        app: awesomeapp-demo
      development:
        app: 
      
      """

    When I run `rake --trace heroku:apps:local`

    Then the output should contain "production is shorthand for the Heroku app awesomeapp"
    And  the output should contain "staging is shorthand for the Heroku app awesomeapp-staging"
    And  the output should contain "demo is shorthand for the Heroku app awesomeapp-demo"

  Scenario: Config file still accepts the old heroku_san format
    Given a file named "config/heroku.yml" with:
      """
      apps:
        production: awesomeapp
        staging: awesomeapp-staging
        demo: awesomeapp-demo
      """

    When I run `rake --trace heroku:apps:local`

    Then the output should contain "production is shorthand for the Heroku app awesomeapp"
    And  the output should contain "staging is shorthand for the Heroku app awesomeapp-staging"
    And  the output should contain "demo is shorthand for the Heroku app awesomeapp-demo"

  Scenario: Tag information can be listed
    Given a file named "config/heroku.yml" with:
      """
      production:
        app: awesomeapp
        tag: ci/*
      staging:
        app: awesomeapp-staging
        tag: staging/*
      demo:
        app: awesomeapp-demo
      """

    When I run `rake --trace all heroku:apps:local`

    Then the output should contain "the production TAG is 'ci/*'"
    And  the output should contain "the staging TAG is 'staging/*'"

  Scenario: heroku:create_config
    When I run `rake --trace heroku:create_config`
    Then a file named "config/heroku.yml" should exist
    And the output should match /Copied example config to ".*.config.heroku.yml"/
    And the output should match /Please edit ".*.config.heroku.yml" with your application's settings./
  
  Scenario: heroku:create_config with an EDITOR set in the environment
    When I run `rake EDITOR=echo --trace heroku:create_config`
    And the output should match /Copied example config to ".*.config.heroku.yml"/
    And the output should match /^echo .*.config.heroku.yml$/

  Scenario: rails generate heroku_san
    When I run `rails generate`
    Then the output should not contain "Could not find generator heroku_san."
    And the output should contain "HerokuSan:\n  heroku_san"
    When I run `rails generate heroku_san`
    Then a file named "config/heroku.yml" should exist
    And the output should contain "create  config/heroku.yml"

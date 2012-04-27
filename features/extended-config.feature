Feature: Extended config

  Background:
    Given a directory named "test-config"
    And I cd to "test-config"
    And I run `git init .`
    And a file named "config.yml" with:
      """
      production:
        TEST_REMOTE: 'hello_production'
      staging:
        TEST_REMOTE: 'goodbye_staging'
      """
    And I run `git add .`
    And I run `git commit -m 'Initial commit'`
    And I cd to ".."
    Given I run `rails new heroku_san_test --quiet --force --database=postgresql --skip-bundle --skip-javascript --skip-test-unit --skip-sprockets`
    And I cd to "heroku_san_test"
    And I overwrite "Gemfile" with:
      """
      source :rubygems
      gem 'rails'
      gem 'heroku_san', :path => '../../../.'
      """
    
  Scenario: Config information can be pulled from a separate git repository
    Given a file named "config/heroku.yml" with:
      """
      config_repo: 'file:///<%= File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test-config') %>'
      production: 
        app: awesomeapp
      staging:
        app: awesomeapp-staging
      demo: 
        app: awesomeapp-demo
      """
    When I run `rake --trace all heroku:config:list:local`

    Then the output should contain "TEST_REMOTE: hello_production"
    And the output should contain "TEST_REMOTE: goodbye_staging"

  Scenario: Config information can be listed
    Given a file named "config/heroku.yml" with:
      """
      production:
        app: awesomeapp
        config:
          TEST_LOCAL: 'hello_production'
      staging:
        app: awesomeapp-staging
        config:
          TEST_LOCAL: 'goodbye_staging'
      demo:
        app: awesomeapp-demo
      """
    When I run `rake --trace all heroku:config:list:local`

    Then the output should contain "TEST_LOCAL: hello_production"
    And  the output should contain "TEST_LOCAL: goodbye_staging"

  Scenario: Config information can be merged between local and remote
    Given a file named "config/heroku.yml" with:
      """
      config_repo: 'file:///<%= File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test-config') %>'
      production:
        app: awesomeapp
        config:
          TEST_LOCAL: 'hello_production'
      staging:
        app: awesomeapp-staging
        config:
          TEST_LOCAL: 'goodbye_staging'
          TEST_REMOTE: 'overridden_by_remote'
      """
    When I run `rake --trace all heroku:config:list:local`

    Then the output should contain "TEST_LOCAL: hello_production"
    And the output should contain "TEST_REMOTE: hello_production"
    And the output should contain "TEST_LOCAL: goodbye_staging"
    And the output should contain "TEST_REMOTE: goodbye_staging"

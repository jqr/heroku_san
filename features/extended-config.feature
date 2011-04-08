Feature: Extended config

  Scenario: Config information can be pulled from a separate git repository
    Given I run `rails new heroku_san_test -O`
    And I cd to "heroku_san_test"
    And I overwrite "Gemfile" with:
      """
      source :rubygems
      gem 'heroku_san', :path => '../../../.'
      """
    Given a file named "config/heroku.yml" with:
      """
      config_repo: git://github.com/rahearn/test-credentials.git
      production: 
        app: awesomeapp
      staging:
        app: awesomeapp-staging
      demo: 
        app: awesomeapp-demo
      """

    When I run `rake heroku:config:list`

    Then the output should contain "production TEST_REMOTE: 'hello world'"
    And the output should contain "staging TEST_REMOTE: 'goodbye world'"

  Scenario: Config information can be listed
    Given I run `rails new heroku_san_test -O`
    And I cd to "heroku_san_test"
    And I overwrite "Gemfile" with:
      """
      source :rubygems
      gem 'heroku_san', :path => '../../../.'
      """
    Given a file named "config/heroku.yml" with:
      """
      production:
        app: awesomeapp
        config:
          TEST_LOCAL: 'hello world'
      staging:
        app: awesomeapp-staging
        config:
          TEST_LOCAL: 'goodbye world'
      demo:
        app: awesomeapp-demo
      """

    When I run `rake heroku:config:list`

    Then the output should contain "production TEST_LOCAL: 'hello world'"
    And  the output should contain "staging TEST_LOCAL: 'goodbye world'"

  Scenario: Config information can be merged between local and remote
    Given I run `rails new heroku_san_test -O`
    And I cd to "heroku_san_test"
    And I overwrite "Gemfile" with:
      """
      source :rubygems
      gem 'heroku_san', :path => '../../../.'
      """
    Given a file named "config/heroku.yml" with:
      """
      config_repo: git://github.com/rahearn/test-credentials.git
      production:
        app: awesomeapp
        config:
          TEST_LOCAL: 'hello world'
      staging:
        app: awesomeapp-staging
        config:
          TEST_LOCAL: 'goodbye world'
          TEST_REMOTE: 'overridden by remote'
      """

    When I run `rake heroku:config:list`

    Then the output should contain "production TEST_LOCAL: 'hello world'"
    And the output should contain "production TEST_REMOTE: 'hello world'"
    And the output should contain "staging TEST_LOCAL: 'goodbye world'"
    And the output should contain "staging TEST_REMOTE: 'goodbye world'"

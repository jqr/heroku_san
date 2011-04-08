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

    When I run `rake all heroku:config:list:local`

    Then the output should contain "production TEST_REMOTE: 'hello_world'"
    And the output should contain "staging TEST_REMOTE: 'goodbye_world'"

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
          TEST_LOCAL: 'hello_world'
      staging:
        app: awesomeapp-staging
        config:
          TEST_LOCAL: 'goodbye_world'
      demo:
        app: awesomeapp-demo
      """

    When I run `rake all heroku:config:list:local`

    Then the output should contain "production TEST_LOCAL: 'hello_world'"
    And  the output should contain "staging TEST_LOCAL: 'goodbye_world'"

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
          TEST_LOCAL: 'hello_world'
      staging:
        app: awesomeapp-staging
        config:
          TEST_LOCAL: 'goodbye_world'
          TEST_REMOTE: 'overridden_by_remote'
      """

    When I run `rake all heroku:config:list:local`

    Then the output should contain "production TEST_LOCAL: 'hello_world'"
    And the output should contain "production TEST_REMOTE: 'hello_world'"
    And the output should contain "staging TEST_LOCAL: 'goodbye_world'"
    And the output should contain "staging TEST_REMOTE: 'goodbye_world'"

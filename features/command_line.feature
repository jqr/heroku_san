Feature: Command Line

  Scenario: Config file can be formatted like Rails' database.yml
    Given I run "rails new heroku_san_test"
    And a file named "heroku_san_test/config/heroku.yml" with:
      """
      production: 
        app: awesomeapp
      staging:
        app: awesomeapp-staging
      demo: 
        app: awesomeapp-demo
      """

    When I cd to "heroku_san_test"
    When I run "rake heroku:apps"

    Then the output should contain "production is shorthand for the Heroku app awesomeapp"
    And  the output should contain "staging is shorthand for the Heroku app awesomeapp-staging"
    And  the output should contain "demo is shorthand for the Heroku app awesomeapp-demo"

  Scenario: Config file still accepts the heroku_san format
    Given I run "rails new heroku_san_test"
    And a file named "heroku_san_test/config/heroku.yml" with:
      """
      apps:
        production: awesomeapp
        staging: awesomeapp-staging
        demo: awesomeapp-demo
      """

    When I cd to "heroku_san_test"
    When I run "rake heroku:apps"

    Then the output should contain "production is shorthand for the Heroku app awesomeapp"
    And  the output should contain "staging is shorthand for the Heroku app awesomeapp-staging"
    And  the output should contain "demo is shorthand for the Heroku app awesomeapp-demo"

Feature: Command Line

@announce
  Scenario: Apps can be configured in the new way
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

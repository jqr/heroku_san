@slow_process @announce-cmd @issue
Feature: github issues
  Given there are bugs
  And everyone wants defect-free software
  When the bugs are fixed
  Then these tests should be green

#  https://github.com/fastestforward/heroku_san/issues/113
#  https://github.com/fastestforward/heroku_san/issues/117
  Scenario: Deploying to an annotated tag fails with 'error: Trying to write non-commit object'
    Given I have a new Rails project
    When I am in the project directory
    And I commit any changes with "Initial commit"
    And I add heroku_san to the Gemfile
    And I run bundle install
    And I generate a new config file
    And I create my project on Heroku
    And I generate a scaffold
    And I commit any changes with "Added droids"
    And I tag the commit with "v1.0" annotated by "I am annotated"
    And I deploy to tag "v1.0"
    Then issue 113 has been fixed

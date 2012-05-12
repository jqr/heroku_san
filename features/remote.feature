@announce-cmd @slow_process
Feature: heroku_san can control a project on Heroku
  WARNING: This WILL create apps on Heroku!
  You must login with the heroku cli before starting
  this test; otherwise it will probably hang the first
  time it tries to do anything with Heroku itself.

  Scenario: Installing on a project
    Given I have a new Rails project
    When I am in the project directory
    And I add heroku_san to the Gemfile
    And I run bundle install
    Then rake reports that the heroku: tasks are available 
    
  Scenario: Manipulates a Rails app on Heroku
    Given I have a new Rails project
    When I am in the project directory
    And I commit any changes with "Initial commit"
    And I add heroku_san to the Gemfile
    And I run bundle install
    And I generate a new config file
    And I create my project on Heroku
    And I list the remote configuration
    And I curl the app home page
    And I configure my project
    And I turn maintenance on
    And I generate a scaffold
    And I commit any changes with "Added droids"
    And I deploy my project
    And I turn maintenance off
    And I restart my project
    And I list all apps on Heroku
    And I install an addon
    Then heroku_san is green
    
  Scenario: Manipulates a Sinatra app on Heroku
    Given I have a new Sinatra project
    When I am in the project directory
    And I commit any changes with "Initial commit"
    And I add heroku_san to the Gemfile
    And I run bundle install
    And I create a new config/heroku.yml file
    And I create my project on Heroku
    And I list the remote configuration
    And I curl the app home page
    And I configure my project
    And I turn maintenance on
    And I add a new action
    And I commit any changes with "Added droids"
    And I deploy my project
    And I turn maintenance off
    And I restart my project
    And I list all apps on Heroku
    And I install an addon
    Then heroku_san is green

@announce @slow_process
Feature: Works with Heroku

  Background:
    Given I run `git clone git://github.com/kmayer/heroku_san_demo.git`
    And I cd to "heroku_san_demo"

  Scenario: Remote commands
    When I run `rake demo deploy`
    Then the output should match /(http:.*-demo.heroku.com deployed to Heroku)|(Everything up-to-date)/

    When I run `rake demo heroku:maintenance_on`
    Then the output should contain "Maintenance mode enabled."

    When I run `rake demo migrate`
    Then the output should contain "Migrating to CreateDroids"
    
    When I run `rake demo restart`
    Then the output should contain "Restarting processes... done"

    When I run `rake demo heroku:maintenance_off`
    Then the output should contain "Maintenance mode disabled."

    When I run `rake demo heroku:rake[db:seed]`
    Then I run `curl -s http://heroku-san-demo-demo.heroku.com/droids.text`
    And the output should contain "C3PO, Marvin, R2D2, Robby"
    
    When I run `rake demo logs`
    Then the output should contain "Starting process with command `rake db:seed`"

    When I run `git co staging`
    And I run `rake deploy`
    Then the output should contain "Defaulting to 'staging' as it matches the current branch"
    Then the output should match /(http:.*-staging.heroku.com deployed to Heroku)|(Everything up-to-date)/
    When I run `curl -s http://heroku-san-demo-staging.heroku.com`
    And the output should contain "Ruby on Rails: Welcome aboard"

    # Runs a before_deploy
    # Runs an after_deploy
    # Adds a collaborator

# Given I run `rake heroku:create_config`
    
#    When I run `rake demo heroku:create`
#    Then the output should contain "somthing about the created app"
#      $ rake all heroku:create
#      heroku create heroku-san-demo-demo
#      Creating heroku-san-demo-demo.... done, stack is bamboo-mri-1.9.2
#      http://heroku-san-demo-demo.heroku.com/ | git@heroku.com:heroku-san-demo-demo.git
#      Git remote heroku added
#      heroku create heroku-san-demo-production
#      Creating heroku-san-demo-production... done, stack is bamboo-mri-1.9.2
#      http://heroku-san-demo-production.heroku.com/ | git@heroku.com:heroku-san-demo-production.git
#      heroku create heroku-san-demo-staging
#      Creating heroku-san-demo-staging... done, stack is bamboo-mri-1.9.2
#      http://heroku-san-demo-staging.heroku.com/ | git@heroku.com:heroku-san-demo-staging.git


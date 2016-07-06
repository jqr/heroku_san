# Heroku San
Helpful rake tasks for Heroku.

[![Build Status](https://secure.travis-ci.org/jqr/heroku_san.png)](http://travis-ci.org/jqr/heroku_san)
[![Code Climate](https://codeclimate.com/github/jqr/heroku_san.png)](https://codeclimate.com/github/jqr/heroku_san)
[![Gemnasium](https://gemnasium.com/jqr/heroku_san.png)](https://gemnasium.com/jqr/heroku_san)

## Install

### Rails 3+

Add this to your `Gemfile`:

```ruby
  group :development do
    gem 'heroku_san'
  end
```

### Rails 2

To install add the following to `config/environment.rb`:

```ruby
  config.gem 'heroku_san'
```

Rake tasks are not automatically loaded from gems, so you’ll need to add the following to your `Rakefile`:

```ruby
  begin
    require 'heroku_san/tasks'
  rescue LoadError
    STDERR.puts "Run `rake gems:install` to install heroku_san"
  end
```

### Sinatra

Update your `Gemfile`:

```ruby
  group :development do
    gem 'heroku_san'
  end
```

Update your `Rakefile`:

```ruby
  require "bundler/setup"
  begin
    require "heroku_san"
    config_file = File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'heroku.yml')
    HerokuSan.project = HerokuSan::Project.new(config_file, :deploy => HerokuSan::Deploy::Sinatra)
    load "heroku_san/tasks.rb"
  rescue LoadError
    # The gem shouldn't be installed in a production environment
  end
```

## Configure

In `config/heroku.yml` you will need to add the Heroku apps that you would like to attach to this project. You can generate this file by running:

### Rails 3+

```sh
  rails generate heroku_san
```

### Everything else

```sh
  rake heroku:create_config
```

Customize the file for your project. If this is a fresh project, `heroku_san` can create all the applications for you, and set each one's RACK_ENV.

```sh
  rake all heroku:create heroku:rack_env
```

Configure your Heroku apps according to `config/heroku.yml` by running:

```sh
  rake all heroku:config
```

## Usage

After configuring your Heroku apps you can use rake tasks to control the
apps.

```sh
  rake production deploy
```

A rake task with the shorthand name of each app is now available and adds that
server to the list that subsequent commands will execute on. Because this list
is additive, you can easily select which servers to run a command on.

```sh
  rake demo staging restart
```

A special rake task 'all' is created that causes any further commands to
execute on all Heroku apps.

```sh
  rake all restart
```

Need to add remotes for each app?

  rake all heroku:remotes

A full list of tasks provided:

```sh
  rake heroku:addons                # Install addons for the application.
  rake heroku:addons:local          # List configured addons, without installing them
  rake heroku:apps                  # Lists configured apps
  rake heroku:apps:local            # Lists configured apps without hitting heroku
  rake heroku:config                # Add config:vars to each application.
  rake heroku:config:list           # Lists config variables as set on Heroku
  rake heroku:config:list:local     # Lists local config variables without setting them
  rake heroku:config:rack_env       # Add proper RACK_ENV to each application
  rake heroku:console               # Opens a remote console
  rake heroku:create                # Creates the Heroku app
  rake heroku:create_config         # Creates an example configuration file
  rake heroku:db:migrate            # Migrates and restarts remote servers
  rake heroku:db:pull               # Pull database from stage to local dev database
  rake heroku:deploy[commit]        # Pushes the given commit, migrates and restarts (default: HEAD)
  rake heroku:deploy:after          # Callback after deploys
  rake heroku:deploy:before         # Callback before deploys
  rake heroku:deploy:force[commit]  # Force-pushes the given commit, migrates and restarts (default: HEAD)
  rake heroku:logs                  # Shows the Heroku logs
  rake heroku:logs:tail             # Tail the Heroku logs (requires logging:expanded)
  rake heroku:maintenance           # Enable maintenance mode
  rake heroku:maintenance_off       # Disable maintenance mode
  rake heroku:maintenance_on        # Enable maintenance mode
  rake heroku:push[commit]          # Pushes the given commit (default: HEAD)
  rake heroku:push:force[commit]    # Force-pushes the given commit (default: HEAD)
  rake heroku:rake[task]            # Runs a rake task remotely
  rake heroku:remotes               # Add git remotes for all apps in this project
  rake heroku:restart               # Restarts remote servers
  rake heroku:shell                 # Opens a bash shell within app
  rake heroku:stage:all             # Select all Heroku apps for later command
```

Frequently used tasks are aliased into the global namespace:

```ruby
  task :all           => 'heroku:stage:all'
  task :deploy        => 'heroku:deploy'
  task 'deploy:force' => 'heroku:deploy:force'
  task :before_deploy => 'heroku:deploy:before'
  task :after_deploy  => 'heroku:deploy:after'
  task :console       => 'heroku:console'
  task :restart       => 'heroku:restart'
  task :migrate       => 'heroku:db:migrate'
  task :logs          => 'heroku:logs:default'
  task 'logs:tail'    => 'heroku:logs:tail'
  task 'shell'        => 'heroku:shell'
```

## Links

Homepage: http://github.com/fastestforward/heroku_san

Issue Tracker: http://github.com/fastestforward/heroku_san/issues

## Contributors

* Elijah Miller (elijah.miller@gmail.com)
* Glenn Roberts (glenn.roberts@siyelo.com)
* Damien Mathieu (42@dmathieu.com)
* Matthew Hassfurder (matthew.hassfurder@gmail.com)
* Peter Jaros
* Lee Semel
* Michael Haddad (michael@ludditetechnology.com)
* Les Hill (leshill@gmail.com)
* Bryan Ash
* Barry Hess (barry@bjhess.com)
* Ryan Ahearn (ryan@craftsoftwaresolutions.com)
* Jon Wood (jon@blankpad.net)
* Mat Schaffer (mat@schaffer.me)
* Jonathan Hironaga (jonathan.hironaga@halogennetwork.com)
* Ken Mayer (ken@bitwrangler.com)
* Matt Burke (https://github.com/spraints)

## License

Copyright (c) 2008-2012 Elijah Miller <mailto:elijah.miller@gmail.com>, released under the MIT license.

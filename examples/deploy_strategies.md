# Deploy Strategies

If you look at the network graphs of `heroku_san` on github, you'll see a number of branches where the only change is the deletion of the following line from the `deploy` task:

  - stage.migrate
  
If more than a few people are will to take the effort to fork a gem just so they can delete 1 line, something smells. The reason is that these forkers were using something other than Rails+ActiveRecord+SQL in their project. Some were using Sinatra, others were using Rails, but with CouchDB. 

The _raison d'être_ for the `heroku_san` gem is to make Heroku deploys dirt simple. So, if people are making whole forks to customize the deploy task, we should make it less painful.

## Enter strategies

[Strategies](need_ref) are an object oriented programming pattern for creating pluggable execution control. There's is now a new class of objects that inherit from `HerokuSan::Deploy::Base`. These objects now control how deploys are executed for you. The Rails strategy, `HerokuSan::Deploy::Base` does exactly what HerokuSan has always done:

  * push to git@heroku.com
  * call rake db:migrate
  * restart
  
On the other hand, the Sinatra strategy, `HerokuSan::Deploy::Sinatra` does nothing more than the base strategy:

  * push to git@heroku.com
  
You can create your own strategies and then configure HerokuSan to use it instead of its default:

## Rails 3 projects

Amend your `Rakefile`:

```ruby
  require 'heroku_san'
  
  class MyStrategy < HerokuSan::Deploy::Base
    def deploy
      super
      # call my own code to do something unique
    end
  end
  
  HerokuSan.project = HerokuSan::Project.new(Rails.root.join("config","heroku.yml"), :deploy => MyStrategy)
```


## Sinatra (and other Rack based apps)

Amend your `Rakefile`

```ruby
  require 'heroku_san'
  
  class MyStrategy < HerokuSan::Deploy::Base
    def deploy
      super
      # call my own code to do something unique
    end
  end
  
  config_file = File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'heroku.yml')
  HerokuSan.project = HerokuSan::Project.new(config_file, :deploy => MyStrategy)
  
  load "heroku_san/tasks.rb"
```
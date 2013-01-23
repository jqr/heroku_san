module HerokuSan
  class Project
    attr_reader :parser

    include Git

    # TODO: replace config_file with dependency injected Parser
    def initialize(config_file, options = {})
      @apps = []
      @app_settings = {}
      @parser = Parser.new(config_file)
      @parser.parse.each do |stage, settings|
        # TODO: Push this eval later (j.i.t.)
        @app_settings[stage] = HerokuSan::Stage.new(stage, settings.merge('deploy' => (options[:deploy]||options['deploy'])))
      end
    end

    def create_config
      parser.create_config
    end
    def config_file
      parser.config_file
    end

    def all
      @app_settings.keys
    end
  
    def [](stage)
      @app_settings[stage]
    end
  
    def <<(*app)
      app.flatten.each do |a|
        @apps << a if all.include?(a)
      end
      self
    end
  
    def apps
      if @apps && !@apps.empty?
        @apps
      else
        @apps = if all.size == 1
          $stdout.puts "Defaulting to #{all.first.inspect} since only one app is defined"
          all
        else
          active_branch = self.git_active_branch
          all.select do |app| 
            app == active_branch and ($stdout.puts("Defaulting to '#{app}' as it matches the current branch") || true)
          end
        end
      end
    end
  
    def each_app
      raise NoApps if apps.empty?
      apps.each do |stage|
        yield(self[stage])
      end
    end
  end
end

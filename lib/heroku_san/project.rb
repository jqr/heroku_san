module HerokuSan
  class Project
    attr_accessor :config_file
    attr_reader :options
    attr_accessor :configuration

    include Git

    # TODO: replace config_file with dependency injected Parser
    def initialize(config_file, options = {})
      @config_file = config_file
      @options = options
      @apps = []
    end

    def stages
      if !@stages
        HerokuSan::Parser.new.parse(self)
      end
      @stages
    end

    def configuration=(configuration)
      @stages = configuration.inject({}) do |stages, (stage, settings)|
        stages[stage] = HerokuSan::Stage.new(stage, settings.merge('deploy' => (options[:deploy]||options['deploy'])))
        stages
      end
    end
    
    def create_config
      # TODO: Convert true/false returns to success/exception
      template = File.expand_path(File.join(File.dirname(__FILE__), '../templates', 'heroku.example.yml'))
      if File.exists?(config_file)
        false
      else
        FileUtils.cp(template, config_file)
        true
      end
    end

    def all
      stages.keys
    end
  
    def [](stage)
      stages[stage]
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

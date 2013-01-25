module HerokuSan
  class Project
    include Git
    attr_accessor :config_file
    attr_reader :options

    def initialize(config_file = '', options = {})
      @config_file = config_file
      @options = options
      @apps = []
    end

    # TODO: Extract the stage factory from this method
    def configuration=(configuration)
      @stages = configuration.inject({}) do |stages, (stage, settings)|
        stages[stage] = HerokuSan::Stage.new(stage, settings.merge('deploy' => (options[:deploy]||options['deploy'])))
        stages
      end
    end

    # TODO: Extract the parser from this method
    def stages
      # Yeah, I know, weird. The parser collaborates with project to create the configuration
      if !@stages
        HerokuSan::Parser.new.parse(self)
      end
      @stages
    end

    def template
      File.expand_path(File.join(File.dirname(__FILE__), '../templates', 'heroku.example.yml'))
    end

    # TODO: Extract this method
    def create_config
      # TODO: Convert true/false returns to success/exception
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
            app == active_branch and ($stdout.puts("Defaulting to '#{app}' as it matches the current branch"); true)
          end
        end
      end
    end
  
    def each_app
      raise NoApps if apps.empty?
      apps.each do |stage|
        yield self[stage]
      end
    end
  end
end

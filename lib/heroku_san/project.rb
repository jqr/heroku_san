module HerokuSan
  class Project
    include Git
    attr_accessor :config_file
    attr_writer :configuration
    attr_reader :options

    def initialize(config_file = '', options = {})
      @config_file = config_file
      @options = options
      @apps = []
    end

    def configuration
      @configuration ||= HerokuSan::Configuration.new(self).stages
    end
    
    def create_config
      HerokuSan::Configuration.new(self).generate_config
    end

    def all
      configuration.keys
    end
  
    def [](stage)
      configuration[stage]
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

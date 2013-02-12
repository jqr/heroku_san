module HerokuSan
  class Project
    include HerokuSan::Git
    attr_reader :config_file
    attr_reader :options
    attr_writer :configuration

    def initialize(config_file = nil, options = {})
      @config_file = config_file
      @options = options
      @apps = []
    end

    def stages
      @stages ||= configuration.stages
    end

    def configuration
      @configuration ||= HerokuSan::Configuration.new(self)
    end

    def create_config
      HerokuSan::Configuration.new(self).generate_config
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
      HerokuSan::Parser.new.merge_external_config!(configuration, stages.values)
      apps.each do |stage|
        yield self[stage]
      end
    end
  end
end

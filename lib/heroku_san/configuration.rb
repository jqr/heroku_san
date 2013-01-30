module HerokuSan
  class Configuration
    attr_reader :config_file
    attr_accessor :configuration
    attr_reader :options

    def initialize(configurable)
      @config_file = configurable.config_file
      default_options = {
          'deploy' => HerokuSan::Deploy::Rails
      }
      @options = default_options.merge(configurable.options || {})
    end

    def parse
      HerokuSan::Parser.new.parse(self)
    end

    def stages
      configured? or parse
      configuration.inject({}) do |stages, (stage, settings)|
        stages[stage] = HerokuSan::Stage.new(stage, settings.merge('deploy' => (options[:deploy]||options['deploy'])))
        stages
      end
    end

    def configured?
      !!configuration
    end

    def template
      File.expand_path(File.join(File.dirname(__FILE__), '../templates', 'heroku.example.yml'))
    end

    def generate_config
      # TODO: Convert true/false returns to success/exception
      if File.exists?(config_file)
        false
      else
        FileUtils.cp(template, config_file)
        true
      end
    end
  end
end
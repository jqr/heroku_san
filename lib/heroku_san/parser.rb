require 'yaml'

module HerokuSan
  class Parser
    include HerokuSan::Git
    attr_accessor :settings
    def parse(parseable)
      @settings = parse_yaml(parseable.config_file)
      convert_from_heroku_san_format
      parseable.external_configuration = @settings.delete 'config_repo'
      each_setting_has_a_config_section
      parseable.configuration = @settings

    end

    def convert_from_heroku_san_format
      (settings.delete('apps') || {}).each_pair do |stage, app_name|
        settings[stage] = {'app' => app_name}
      end
    end

    def each_setting_has_a_config_section
      settings.keys.each do |name|
        settings[name] ||= {}
        settings[name]['config'] ||= {}
      end
    end

    def merge_external_config!(parseable, stages)
      extra_config = parse_external_config!(parseable.external_configuration)
      return unless extra_config
      stages.each do |stage|
        stage.config.merge!(extra_config[stage.name]) if extra_config[stage.name]
      end
    end

    def parse_external_config!(config_repo)
      return if config_repo.nil?
      require 'tmpdir'
      Dir.mktmpdir do |dir|
        git_clone config_repo, dir
        parse_yaml File.join(dir, 'config.yml')
      end
    end

      private

    def parse_yaml(config_file)
      if File.exists?(config_file)
        if defined?(ERB)
          YAML.load(ERB.new(File.read(config_file)).result)
        else
          YAML.load_file(config_file)
        end
      else
        {}
      end
    end
  end
end

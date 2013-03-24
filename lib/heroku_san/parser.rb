require 'yaml'

module HerokuSan
  class Parser
    include Git
    attr_accessor :settings

    def parse(parseable)
      @settings = parse_yaml(parseable.config_file)

      convert_from_heroku_san_format
      each_setting_has_a_config_section
      merge_extra(external_config)
      parseable.configuration = settings
    end

    def convert_from_heroku_san_format
      (settings.delete('apps') || {}).each_pair do |stage, app_name|
        settings[stage] = {'app' => app_name}
      end
    end

    def external_config
      if (config_repo = settings.delete('config_repo'))
        require 'tmpdir'
        Dir.mktmpdir do |dir|
          git_clone(config_repo, dir)
          parse_yaml(File.join(dir, 'config.yml'))
        end
      else
        {}
      end
    end

    def each_setting_has_a_config_section
      settings.keys.each do |name|
        settings[name] ||= {}
        settings[name]['config'] ||= {}
      end
    end

    def merge_extra(extra_config)
      settings.keys.each do |name|
        settings[name]['config'].merge!(extra_config[name]) if extra_config[name]
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

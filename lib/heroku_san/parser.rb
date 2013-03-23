require 'yaml'

module HerokuSan
  class Parser
    attr_reader :config_file

    def initialize(config_file)
      @config_file = config_file
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

    def parse
      app_settings = parse_yaml(config_file)

      # support heroku_san format
      if app_settings.has_key? 'apps'
        app_settings = app_settings['apps']
        app_settings.each_pair do |stage, app_name|
          app_settings[stage] = {'app' => app_name}
        end
      end

      # load external config
      if (config_repo = app_settings.delete('config_repo'))
        require 'tmpdir'
        tmp_config_dir = Dir.mktmpdir
        tmp_config_file = File.join tmp_config_dir, 'config.yml'
        git_clone(config_repo, tmp_config_dir)
        extra_config = parse_yaml(tmp_config_file)
      else
        extra_config = {}
      end

      # make sure each app has a 'config' section & merge w/extra
      app_settings.keys.each do |name|
        app_settings[name] ||= {}
        app_settings[name]['config'] ||= {}
        app_settings[name]['config'].merge!(extra_config[name]) if extra_config[name]
      end

      app_settings
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

module HerokuSan
  class Parser
    attr_reader :config_file

    def parse(parseable)
      settings = parse_yaml(parseable.config_file)

      # support heroku_san format
      if settings.has_key? 'apps'
        settings = settings['apps']
        settings.each_pair do |stage, app_name|
          settings[stage] = {'app' => app_name}
        end
      end

      # load external config
      if (config_repo = settings.delete('config_repo'))
        require 'tmpdir'
        tmp_config_dir = Dir.mktmpdir
        tmp_config_file = File.join tmp_config_dir, 'config.yml'
        git_clone(config_repo, tmp_config_dir)
        extra_config = parse_yaml(tmp_config_file)
      else
        extra_config = {}
      end

      # make sure each app has a 'config' section & merge w/extra
      settings.keys.each do |name|
        settings[name] ||= {}
        settings[name]['config'] ||= {}
        settings[name]['config'].merge!(extra_config[name]) if extra_config[name]
      end

      parseable.configuration = settings
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
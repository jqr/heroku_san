require 'time'

module HerokuSan
  class API
    def initialize(options = {})
      @options = options
    end

    def sh(app, *command)
      preflight_check_for_cli

      cmd = (command + ['--app', app]).compact

      show_command = cmd.join(' ')
      $stderr.puts show_command if @debug

      ok = Bundler.with_clean_env { system "heroku", *cmd }

      status = $?
      ok or fail "Command failed with status (#{status.exitstatus}): [heroku #{show_command}]"
    end

    def method_missing(name, *args)
      heroku_api.send(name, *args)
    rescue Heroku::API::Errors::ErrorWithResponse => error
      status = error.response.headers["Status"]
      msg = JSON.parse(error.response.body)['error'] rescue '???'
      error.set_backtrace([])
      $stderr.puts "\nHeroku API ERROR: #{status} (#{msg})\n\n"
      raise error
    end

    private

    def heroku_api
      @heroku_api ||= begin
        @options[:api_key] ||= auth_token
        Heroku::API.new(@options)
      end
    end

    def auth_token
      ENV['HEROKU_API_KEY'] || Bundler.with_clean_env { `heroku auth:token`.chomp }
    rescue Errno::ENOENT
      nil
    end

    def preflight_check_for_cli
      raise "The Heroku Toolbelt is required for this action. http://toolbelt.heroku.com" if Bundler.with_clean_env { system('heroku version') == nil }
    end
  end
end

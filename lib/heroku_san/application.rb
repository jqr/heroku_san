require 'heroku-api'

MOCK = false unless defined?(MOCK)

module HerokuSan
  class Application
    def initialize app_name
      @app_name = app_name
      @api = HerokuSan::API.new(:api_key => auth_token, :mock => MOCK)
    end

    def ensure_one_worker_running
      one_up = false
      until one_up do
        processes = @api.get_ps(@app_name).body
        web_processes = processes.select { |p| p["process"] =~ /web\./ }

        web_processes.each do |process|
          case process["state"]
          when "up"
            one_up = true
          when "crashed"
            @api.post_ps_restart(@app_name, ps: process["process"])
          end
        end
      end
    end

    def ensure_all_workers_running
      while true do
        processes = @api.get_ps(@app_name).body

        return if processes.all? {|p| p["state"] == "up"}

        processes.each do |process|
          case process["state"]
          when "crashed"
            @api.post_ps_restart(@app_name, ps: process["process"])
          end
        end
      end
    end

    private

    def auth_token
      @auth_token ||= (ENV['HEROKU_API_KEY'] || `heroku auth:token`.chomp unless MOCK)
    end
  end
end

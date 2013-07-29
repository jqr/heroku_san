require 'heroku-api'

module HerokuSan
  module Application
    def ensure_one_worker_running(at_least = 1)
      begin
        web_processes = heroku.get_ps(app).body.select { |p| p["process"] =~ /web\./ }
      end until restart_processes(web_processes) >= at_least
    end

    def ensure_all_workers_running
      while true do
        processes = heroku.get_ps(app).body

        return if processes.all? { |p| p["state"] == "up" }

        restart_processes(processes)
      end
    end

    private

    def restart_processes(web_processes)
      up = 0
      web_processes.each do |process|
        case process["state"]
          when "up"
            up += 1
          when "crashed"
            heroku.post_ps_restart(app, ps: process["process"])
        end
      end
      up
    end
  end
end

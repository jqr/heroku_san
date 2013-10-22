require 'spec_helper'

module HerokuSan
  describe HerokuSan::Application do
    let(:stage) { Factory::Stage.build('production', {"deploy" => HerokuSan::Deploy::Rails, "app" => "awesomeapp", "stack" => "cedar"}) }
    let(:response) { double }

    before do
      stage.heroku.stub(:get_ps).with(stage.app) { response }
    end

    describe "#ensure_one_worker_running" do
      # API: {"action" => "up", "app_name" => "awesomeapp", "attached" => false, "command" => "thin -p $PORT -e $RACK_ENV -R $HEROKU_RACK start", "elapsed" => 0, "pretty_state" => "created for 0s", "process" => "web.1", "rendezvous_url" => nil, "slug" => "NONE", "state" => "created", "transitioned_at" => "2013/07/28 15:04:24 -0700", "type" => "Dyno", "upid" => "56003928"}
      let(:none_running) do
        [
          {"process" => "worker.1", "state" => "up"},
          {"process" => "web.1", "state" => "starting"},
          {"process" => "web.2", "state" => "starting"}
        ]
      end
      let(:one_running_with_crash) do
        [
          {"process" => "worker.1", "state" => "up"},
          {"process" => "web.1", "state" => "crashed"},
          {"process" => "web.2", "state" => "up"}
        ]
      end

      it "should block until at least one worker is running, and restart any crashed workers it sees" do

        with_app(stage, 'name' => stage.app) do |app_data|
          response.should_receive(:body).twice.and_return(none_running, one_running_with_crash)
          stage.heroku.should_receive(:post_ps_restart).with(stage.app, ps: 'web.1')

          stage.ensure_one_worker_running
        end
      end
    end

    describe "#ensure_all_workers_running" do
      let(:some_crashes) do
        [
          {"process" => "worker.1", "state" => "crashed"},
          {"process" => "web.1", "state" => "crashed"},
          {"process" => "web.2", "state" => "starting"}
        ]
      end
      let(:some_restarting) do
        [
          {"process" => "worker.1", "state" => "restarting"},
          {"process" => "web.1", "state" => "restarting"},
          {"process" => "web.2", "state" => "up"}
        ]
      end
      let(:one_crash) do
        [
          {"process" => "worker.1", "state" => "crashed"},
          {"process" => "web.1", "state" => "up"},
          {"process" => "web.2", "state" => "up"}
        ]
      end
      let(:all_up) do
        [
          {"process" => "worker.1", "state" => "up"},
          {"process" => "web.1", "state" => "up"},
          {"process" => "web.2", "state" => "up"}
        ]
      end

      it "should block until all workers are running, and restart any crashed workers it sees" do
        with_app(stage, 'name' => stage.app) do |app_data|
          response.should_receive(:body).exactly(4).times.and_return(some_crashes, some_restarting, one_crash, all_up)
          stage.heroku.should_receive(:post_ps_restart).with(stage.app, ps: 'worker.1').twice
          stage.heroku.should_receive(:post_ps_restart).with(stage.app, ps: 'web.1').once

          stage.ensure_all_workers_running
        end
      end
    end
  end
end

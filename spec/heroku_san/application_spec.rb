require 'spec_helper'
require_relative '../../lib/heroku_san/application.rb'

module HerokuSan
describe HerokuSan::Application do
  let(:application) { HerokuSan::Application.new(app_name)}
  let(:app_name) { stub }
  let(:api) { stub }

  before do
    HerokuSan::API.stub(:new) { api }
  end

  describe "#ensure_one_worker_running" do
    let(:response) { stub }
    let(:none_running) do
      [
        {
          "process" => "worker.1",
          "state" => "up"
        },
        {
          "process" => "web.1",
          "state" => "starting"
        },
        {
          "process" => "web.2",
          "state" => "starting"
        }
      ]
    end
    let(:one_running_with_crash) do
      [
        {
          "process" => "worker.1",
          "state" => "up"
        },
        {
          "process" => "web.1",
          "state" => "crashed"
        },
        {
          "process" => "web.2",
          "state" => "up"
        }
      ]
    end

    before do
      api.stub(:get_ps).with(app_name) { response }
    end

    it "should block until at least one worker is running, and restart any crashed workers it sees" do
      response.should_receive(:body).twice.and_return(none_running, one_running_with_crash)
      api.should_receive(:post_ps_restart).with(app_name, ps: 'web.1')

      application.ensure_one_worker_running
    end
  end

  describe "#ensure_all_workers_running" do
    let(:response) { stub }
    let(:some_crashes) do
      [
        {
          "process" => "worker.1",
          "state" => "crashed"
        },
        {
          "process" => "web.1",
          "state" => "crashed"
        },
        {
          "process" => "web.2",
          "state" => "starting"
        }
      ]
    end
    let(:some_restarting) do
      [
        {
          "process" => "worker.1",
          "state" => "restarting"
        },
        {
          "process" => "web.1",
          "state" => "restarting"
        },
        {
          "process" => "web.2",
          "state" => "up"
        }
      ]
    end
    let(:one_crash) do
      [
        {
          "process" => "worker.1",
          "state" => "crashed"
        },
        {
          "process" => "web.1",
          "state" => "up"
        },
        {
          "process" => "web.2",
          "state" => "up"
        }
      ]
    end
    let(:all_up) do
      [
        {
          "process" => "worker.1",
          "state" => "up"
        },
        {
          "process" => "web.1",
          "state" => "up"
        },
        {
          "process" => "web.2",
          "state" => "up"
        }
      ]
    end

    before do
      api.stub(:get_ps).with(app_name) { response }
    end

    it "should block until all workers are running, and restart any crashed workers it sees" do
      response.should_receive(:body).exactly(4).times.and_return(some_crashes, some_restarting, one_crash, all_up)
      api.should_receive(:post_ps_restart).with(app_name, ps: 'worker.1').twice
      api.should_receive(:post_ps_restart).with(app_name, ps: 'web.1').once

      application.ensure_all_workers_running
    end
  end
end
end

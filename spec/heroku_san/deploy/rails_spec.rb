require 'spec_helper'

module HerokuSan
  module Deploy
    describe Rails do
      let(:stage) { Factory::Stage.build('test', {"app" => "awesomeapp", "deploy" => 'HerokuSan::Deploy::Rails'}) }

      it "calls push, rake db:migrate & restart" do
        subject = described_class.new(stage, {})
        stage.should_receive(:push) { "pushed" } # "mock" super
        stage.should_receive(:run).with('rake db:migrate') { "migrated" }
        stage.should_receive(:restart) { "restarted" }
        subject.deploy
      end
    end
  end
end

require 'spec_helper'

module HerokuSan
  module Deploy
    describe Rails do
      let(:stage) { Factory::Stage.build('test', {"app" => "awesomeapp", "deploy" => 'HerokuSan::Deploy::Rails'}) }

      it "calls push, rake db:migrate & restart" do
        subject = described_class.new(stage, {})
        expect(stage).to receive(:push) { "pushed" } # "mock" super
        expect(stage).to receive(:run).with('rake db:migrate') { "migrated" }
        expect(stage).to receive(:restart) { "restarted" }
        subject.deploy
      end
    end
  end
end

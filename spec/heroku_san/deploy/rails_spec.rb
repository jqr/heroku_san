require 'spec_helper'

module HerokuSan
  module Deploy
    describe Rails do
      let(:stage) { HerokuSan::Stage.new('test', {"app" => "awesomeapp", "deploy" => 'HerokuSan::Deploy::Rails'}) }

      it "calls migrate" do
        subject = described_class.new(stage, {})
        stage.should_receive(:push) # "mock" super
        stage.should_receive(:rake).with('db:migrate')
        stage.should_receive(:restart)
        subject.deploy
      end
    end
  end
end

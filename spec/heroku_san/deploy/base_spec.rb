require 'spec_helper'

module HerokuSan
  module Deploy
    describe Base do
      let(:stage) { Factory::Stage.build('test', {"app" => "awesomeapp", "deploy" => 'HerokuSan::Deploy::Base'}) }
      
      it "calls push" do
        subject = described_class.new(stage)
        stage.should_receive(:push).with(nil, nil)
        subject.deploy
      end
      
      it "calls push(sha)" do
        subject = described_class.new(stage, 'sha')
        stage.should_receive(:push).with('sha', nil)
        subject.deploy
      end
      
      it "calls push(nil, :force)" do
        subject = described_class.new(stage, nil, :force)
        stage.should_receive(:push).with(nil, :force)
        subject.deploy
      end

      it "calls push(sha, :force)" do
        subject = described_class.new(stage, 'sha', :force)
        stage.should_receive(:push).with('sha', :force)
        subject.deploy
      end
    end
  end
end

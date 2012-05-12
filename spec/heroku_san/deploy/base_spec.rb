require 'spec_helper'

module HerokuSan
  module Deploy
    describe Base do
      let(:stage) { HerokuSan::Stage.new('test', {"app" => "awesomeapp", "deploy" => 'HerokuSan::Deploy::Base'}) }
      
      it "calls push" do
        subject = described_class.new(stage, {})
        stage.should_receive(:push).with(nil, nil)
        subject.deploy
      end
      
      it "calls push(sha)" do
        subject = described_class.new(stage, {:commit => 'sha'})
        stage.should_receive(:push).with('sha', nil)
        subject.deploy
      end
      
      it "calls push(nil, :force)" do
        subject = described_class.new(stage, {:force => true})
        stage.should_receive(:push).with(nil, true)
        subject.deploy
      end

      it "calls push(sha, :force)" do
        subject = described_class.new(stage, {:commit => 'sha', :force => true})
        stage.should_receive(:push).with('sha', true)
        subject.deploy
      end
    end
  end
end

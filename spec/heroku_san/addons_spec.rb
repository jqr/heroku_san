require 'spec_helper'

describe HerokuSan::Addons do
  subject { described_class.new stage }
  let(:stage) { mock('stage', :app => 'awesomeapp') }

  context '#needed' do
    it 'should list configured addons that are not installed' do
      subject.should_receive(:installed).and_return(['installed:addon'])
      stage.should_receive(:addons).and_return(['installed:addon', 'other:addon'])
      subject.needed.should == ['other:addon']
    end
  end

  context do
    before { subject.should_receive(:`).with("heroku addons --app awesomeapp").and_return(addons_response) }
    let(:addons_response) { <<END_OUTPUT }
one:addon

--- not configured ---
two:addon               http://heroku.com/myapps/awesomeapp/addons/two:addon
END_OUTPUT

    it 'should list addons that are installed in the app' do
      subject.installed.should == ['one:addon', 'two:addon']
    end

    it 'should list addons that are installed in the app and that need configuration' do
      subject.broken.should == [ ['two:addon', 'http://heroku.com/myapps/awesomeapp/addons/two:addon'] ]
    end
  end
end

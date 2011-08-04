require 'spec_helper'

describe HerokuSan::Stage do
  subject { HerokuSan::Stage.new('production', {"app" => "awesomeapp", "stack" => "bamboo-ree-1.8.7"})}

  context "initializes" do
    subject { HerokuSan::Stage.new('production', 
      {"stack" => "cedar", 
       "app"   => "awesomeapp-demo", 
       "tag"   => "demo/*", 
       "config"=> {"BUNDLE_WITHOUT"=>"development:test"}
      })}

    its(:name)   { should == 'production' }
    its(:app)    { should == 'awesomeapp-demo' }
    its(:stack)  { should == 'cedar' }
    its(:tag)    { should == "demo/*" }
    its(:config) { should == {"BUNDLE_WITHOUT"=>"development:test"} }
    its(:repo)   { should == 'git@heroku.com:awesomeapp-demo.git' }
  end
  
  context "celadon cedar stack has a different API" do
    describe "#stack" do
      it "returns the name of the stack from Heroku" do
        subject = HerokuSan::Stage.new('production', {"app" => "awesomeapp"})
        subject.should_receive("`").with("heroku stack --app awesomeapp") {
<<EOT
  aspen-mri-1.8.6
* bamboo-mri-1.9.2
  bamboo-ree-1.8.7
  cedar (beta)
EOT
        }
        subject.stack.should == 'bamboo-mri-1.9.2'
      end
    
      it "returns the stack name from the config if it is set there" do
        subject = HerokuSan::Stage.new('production', {"app" => "awesomeapp", "stack" => "cedar"})
        subject.should_not_receive("`")
        subject.stack.should == 'cedar'
      end
    end
        
    describe "#run" do
      it "runs commands using the pre-cedar format" do
        subject.should_receive(:sh).with("heroku run:rake foo bar bleh --app awesomeapp")
        subject.run('rake', 'foo bar bleh')
      end
      it "runs commands using the new cedar format" do
        subject = HerokuSan::Stage.new('production', {"app" => "awesomeapp", "stack" => "cedar"})
        subject.should_receive(:sh).with("heroku run worker foo bar bleh --app awesomeapp")
        subject.run('worker', 'foo bar bleh')
      end
    end
  end

  describe "#migrate" do
    it "runs rake db:migrate" do
      subject.should_receive(:sh).with("heroku run:rake db:migrate --app awesomeapp")
      subject.should_receive(:sh).with("heroku restart --app awesomeapp")
      subject.migrate
    end
  end
  
  describe "#maintenance" do      
    it ":on" do
      subject.should_receive(:sh).with("heroku maintenance:on --app awesomeapp")
      subject.maintenance :on
    end

    it ":off" do
      subject.should_receive(:sh).with("heroku maintenance:off --app awesomeapp")
      subject.maintenance :off
    end
    
    it "otherwise raises an ArgumentError" do
      expect do
        subject.maintenance :busy
      end.to raise_error ArgumentError, "Action #{:busy.inspect} must be one of (:on, :off)"      
    end
  end

  describe "#create" do
    it "creates an app on heroku" do
      subject.should_receive(:sh).with("heroku apps:create awesomeapp --stack bamboo-ree-1.8.7")
      subject.create
    end
    it "uses the default stack if none is given" do
      subject = HerokuSan::Stage.new('production', {"app" => "awesomeapp"})
      subject.should_receive(:sh).with("heroku apps:create awesomeapp")
      subject.create
    end
  end
  
  describe "#sharing_add" do
    it "add collaborators" do
      subject.should_receive(:sh).with("heroku sharing:add email@example.com --app awesomeapp")
      subject.sharing_add 'email@example.com'
    end
  end

  describe "#sharing_remove" do
    it "removes collaborators" do
      subject.should_receive(:sh).with("heroku sharing:remove email@example.com --app awesomeapp")
      subject.sharing_remove 'email@example.com'
    end
  end

  describe "#long_config" do
    it "prints out the remote config" do
      subject.should_receive(:sh).with("heroku config --long --app awesomeapp") {
<<EOT
BUNDLE_WITHOUT      => development:test
DATABASE_URL        => postgres://thnodhxrzn:T0-UwxLyFgXcnBSHmyhv@ec2-50-19-216-194.compute-1.amazonaws.com/thnodhxrzn
LANG                => en_US.UTF-8
RACK_ENV            => production
SHARED_DATABASE_URL => postgres://thnodhxrzn:T0-UwxLyFgXcnBSHmyhv@ec2-50-19-216-194.compute-1.amazonaws.com/thnodhxrzn
EOT
      }
      subject.long_config
    end
  end

  describe "#restart" do
    it "restarts an app" do
      subject.should_receive(:sh).with("heroku restart --app awesomeapp")
      subject.restart
    end
  end
  
  describe "#logs" do
    it "returns log files" do
      subject.should_receive(:sh).with("heroku logs --app awesomeapp")
      subject.logs
    end
  end

end
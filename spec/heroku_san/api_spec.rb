require 'spec_helper'

# https://github.com/fastestforward/heroku_san/issues/105
module HerokuSan
describe HerokuSan::API do
  subject(:api) { HerokuSan::API.new(:api_key => 'key', :double => true)}
  it "is a proxy to the Heroku::API" do
    expect_any_instance_of(Heroku::API).to receive(:api_method).with(1, 2, {:arg => 3}) {true}
    expect(api.api_method(1, 2, {:arg => 3})).to be_truthy
  end

  it "reports Excon errors in a more human readable format" do
    error_message = 'Name is already taken'
    status_message = '000 Status'
    response = double("Response", :body => %Q[{"error":"#{error_message}"}], :headers => {'Status' => status_message})
    expect_any_instance_of(Heroku::API).to receive(:api_method).and_raise(Heroku::API::Errors::ErrorWithResponse.new("excon message", response))

    expect($stderr).to receive(:puts).with("\nHeroku API ERROR: #{status_message} (#{error_message})\n\n")

    expect {
      api.api_method
    }.to raise_error(Heroku::API::Errors::ErrorWithResponse, "excon message") {|error|
      expect(error.backtrace).to eq []
    }
  end
end
end

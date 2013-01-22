require 'spec_helper'

# https://github.com/fastestforward/heroku_san/issues/105

=begin
Expected(202) <=> Actual(422 Unprocessable Entity)
  request => {:connect_timeout=>60, :headers=>{"Accept"=>"application/json", "Accept-Encoding"=>"gzip", "Authorization"=>"Basic OjUwZTc4NjgxZDhmYzcxZDI3Yzc5ZTM3MTZhNDk3Nzk1MzU2Mzk4ZTM=", "User-Agent"=>"heroku-rb/0.1.8", "X-Heroku-API-Version"=>"3", "X-Ruby-Version"=>"1.9.2", "X-Ruby-Platform"=>"x86_64-darwin10.8.0", "Host"=>"api.heroku.com:443", "Content-Length"=>0}, :instrumentor_name=>"excon", :mock=>false, :read_timeout=>60, :retry_limit=>4, :ssl_ca_file=>"/Users/kmayer/.rvm/gems/ruby-1.9.2-p320/gems/excon-0.13.4/data/cacert.pem", :ssl_verify_peer=>true, :write_timeout=>60, :host=>"api.heroku.com", :path=>"/apps", :port=>"443", :query=>{"app[name]"=>"stark-window-5734"}, :scheme=>"https", :expects=>202, :method=>:post}
  response => #<Excon::Response:0x00000100e07288 @body="{\"error\":\"Name is already taken\"}", @headers={"Cache-Control"=>"no-cache", "Content-Type"=>"application/json; charset=utf-8", "Date"=>"Sun, 29 Jul 2012 19:24:33 GMT", "Server"=>"nginx/1.0.14", "Status"=>"422 Unprocessable Entity", "Strict-Transport-Security"=>"max-age=500", "X-RateLimit-Limit"=>"486", "X-RateLimit-Remaining"=>"485", "X-RateLimit-Reset"=>"1343589933", "X-Runtime"=>"426", "Content-Length"=>"33", "Connection"=>"keep-alive"}, @status=422>
=end

describe "Handle Excon exceptions" do
  it "should report the error in a more readable format"
end
def random_name
  "heroku-rb-#{SecureRandom.hex(10)}"
end

def random_email_address
  "email@#{random_name}.com"
end

def with_app(subject, params={}, &block)
  begin
    data = subject.heroku.post_app(params).body
    @name = data['name']
    ready = false
    until ready
      ready = subject.heroku.request(:method => :put, :path => "/apps/#{@name}/status").status == 201
    end
    yield(data)
  ensure
    subject.heroku.delete_app(@name) rescue nil
  end
end

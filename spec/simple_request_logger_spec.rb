require 'spec_helper'

class MyLogger < Jimmy::SimpleRequestLogger
  def stream
    @stream ||= StringIO.new
  end
end

describe Jimmy::SimpleRequestLogger do
  it 'behaves as a Rack middleware' do
    app = proc { |_env| [:status, :headers, :body] }
    middleware = MyLogger.new(app)
    s, h, r = middleware.call('PATH_INFO' => '/gggg/')
    expect([s, h, r]).to eq([:status, :headers, :body])
  end

  describe 'the log entry' do
    let(:rsp_code) { 200 }
    let(:env) { {} }
    let(:middleware) { MyLogger.new(upstream) }
    let(:upstream) do
      proc { |_env| [rsp_code, { 'Content-Type' => 'text/html' }, %w(hi there)] }
    end

    subject(:json) do
      # the timestamp in the json file has a lower resolution than is
      # available from Time::now, so if we're not careful here it can
      # appear to have run in the past.
      middleware.call(env)
      JSON.parse(middleware.stream.string.lines.last)
    end

    it 'starts with current time' do
      @start_time = Time.at(Time.now.to_i).utc # whole number of seconds
      key, value = json.first
      expect(key).to eq 'timestamp'
      expect(Time.parse(value)).to be_between(@start_time, Time.now.utc)
    end

    it 'includes the HTTP response_code' do
      expect(json['response_code']).to eq 200
    end

    it 'writes the logs through the Writer' do
      expect_any_instance_of(Jimmy::Writer).to receive(:write).twice
      middleware.call('PATH_INFO' => '/gggg/')
      middleware.call('PATH_INFO' => '/hhhhhhh/')
    end

    context 'the request duration' do
      let(:upstream) do
        # There must be a better way to test this than by waiting for
        # the wall clock.  Pref. not using timecop either
        proc do|_env|
          sleep(2)
          [rsp_code, { 'Content-Type' => 'text/html' }, %w(hi there)]
        end
      end
      it 'is logged' do
        expect(json['duration']).to be > 2.0
      end
    end

    context 'when calling upstream causes an exception' do
      let(:upstream) do
        proc do|_env|
          raise ArgumentError, "Something went wrong!"
        end
      end

      it 'reraises the exception' do
        expect { json }.to raise_error(ArgumentError, 'Something went wrong!')
      end

      it 'logs the error' do
        expect { json }.to raise_error(ArgumentError, 'Something went wrong!')
        json = JSON.parse(middleware.stream.string.lines.last)

        expect(json['response_code']).to eq '500'
        expect(json['error_class']).to eq 'ArgumentError'
        expect(json['error_message']).to eq 'Something went wrong!'
        expect(json['error_backtrace']).to be_present
      end
    end

    context 'when the REMOTE_ADDR is set in rack env' do
      let(:env) { { 'REMOTE_ADDR' => '80.79.78.77' } }
      it 'is included' do
        expect(json['remote_address']).to eq('80.79.78.77')
      end
    end

    context 'when HTTP_X_REQUEST_ID is set (e.g. by upstream loadbalancer)' do
      let(:env) { { 'HTTP_X_REQUEST_ID' => 'thequickbrownfox' } }
      it 'is included' do
        expect(json['request_id']).to eq('thequickbrownfox')
      end
    end
    context 'when the X-Request-ID response header is set' do
      let(:upstream) do
        proc do|_env|
          [rsp_code, { 'Content-Type' => 'text/html',
                       'X-Request-Id' => 'overthelazydog'
                     }, %w(hi there)]
        end
      end
      it 'is included' do
        expect(json['request_id']).to eq('overthelazydog')
      end
    end

    context 'when X-Request-ID is set in request and response' do
      let(:env) { { 'HTTP_X_REQUEST_ID' => 'thequickbrownfox' } }
      let(:upstream) do
        proc do|_env|
          [rsp_code, { 'Content-Type' => 'text/html',
                       'X-Request-Id' => 'overthelazydog'
                     }, %w(hi there)]
        end
      end
      it 'the response header takes priority' do
        # they probably shouldn't ever differ, but
        # e.g. ActionDispatch::RequestId middleware strips out
        # non-alphanum characters and truncates to 255, so let's be
        # consistent
        expect(json['request_id']).to eq('overthelazydog')
      end
    end

    context 'when additional context is configured' do
      before do
        Jimmy.configure do |config|
          config.additional_context = ->(env) { { username: env['USERNAME'] } }
        end
      end
      let(:env) { { 'USERNAME' => 'joe.bloggs' } }

      it 'applies additional context to every request' do
        expect(json['username']).to eq('joe.bloggs')
      end
    end

    context 'when the developer makes a mistake in the additional context that throws an error' do
      before do
        Jimmy.configure do |config|
          config.additional_context = ->(env) { { username: env.fetch('USERNAME') } }
        end
      end
      after do
        Jimmy.configure do |config|
          config.additional_context = ->(_) { {} }
        end
      end
      let(:env) { {} }

      it 'does not throw an error' do
        expect { json }.to_not raise_error
      end

      it 'does not set the key' do
        expect(json).to_not have_key('username')
      end
    end

    context 'for an example GET request' do
      let(:env) do
        {
          'GATEWAY_INTERFACE' => 'CGI/1.1',
          'PATH_INFO' => '/ping',
          'QUERY_STRING' => 'cmd=five_hundred',
          'REMOTE_ADDR' => '127.0.0.1',
          'REMOTE_HOST' => 'localhost',
          'REQUEST_METHOD' => 'GET',
          'REQUEST_URI' => 'http://localhost:3000/ping?cmd=five_hundred',
          'SCRIPT_NAME' => '',
          'SERVER_NAME' => 'localhost',
          'SERVER_PORT' => '3000',
          'SERVER_PROTOCOL' => 'HTTP/1.1',
          'SERVER_SOFTWARE' => 'WEBrick/1.3.1 (Ruby/2.0.0/2013-11-22)',
          'HTTP_USER_AGENT' =>           'curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8x zlib/1.2',
          'HTTP_HOST' => 'localhost:3000',
          'HTTP_ACCEPT' => '*/*',
          'HTTP_REFERER' => 'http://www.google.com',
          'HTTP_VERSION' => 'HTTP/1.1',
          'REQUEST_PATH' => '/ping',
          'ORIGINAL_FULLPATH' => '/ping?cmd=five_hundred'
        }
      end

      it 'returns the correct uri' do
        expect(subject['uri']).to eq('/ping?cmd=five_hundred')
      end
      it 'returns the correct request_method' do
        expect(subject['request_method']).to eq('GET')
      end
      it 'returns the correct referer' do
        expect(subject['referer']).to eq('http://www.google.com')
      end
      it 'returns the correct query_params' do
        expect(subject['query_params']).to eq('cmd' => ['five_hundred'])
      end
      it 'returns the correct user_agent' do
        expect(subject['user_agent']).to eq('curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8x zlib/1.2')
      end
    end

    context 'when the request has a body' do
      let(:content_type_header) { {} }
      let(:body_stream) { StringIO.new('p1=foo&p2=bar', 'r') }
      let(:env) do
        {
          'GATEWAY_INTERFACE' => 'CGI/1.1',
          'PATH_INFO' => '/ping',
          'CONTENT_LENGTH' => 13,
          'QUERY_STRING' => 'cmd=five_hundred',
          'REQUEST_METHOD' => 'POST',
          'REQUEST_URI' => 'http://localhost:3000/ping?cmd=five_hundred',
          'HTTP_VERSION' => 'HTTP/1.1',
          'REQUEST_PATH' => '/ping',
          'ORIGINAL_FULLPATH' => '/ping?cmd=five_hundred',
          'rack.input' => body_stream
        }.merge(content_type_header)
      end

      subject(:body_params) { json['body_params'] }

      context 'when there is no declared content-type' do
        it 'includes body parameters' do
          expect(body_params).to eq('p1' => 'foo', 'p2' => 'bar')
        end
      end

      context 'when content-type is application/x-www-form-urlencoded' do
        let(:content_type_header) do
          {
            'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
          }
        end

        it 'includes body parameters' do
          expect(body_params).to eq('p1' => 'foo', 'p2' => 'bar')
        end
      end
      context 'when content-type is multipart (and might be very long)' do
        let(:content_type_header) do
          {
            'CONTENT_TYPE' => 'multipart/form-data'
          }
        end

        it 'does not include body params' do
          expect(body_params).to be_nil
        end
      end
    end
  end

  it 'allows subsequent middlewares or apps to append to the log entry' do
    app = proc do|env|
      env['sb.simple_request_logger.entry'] << { my_key: 'forty two' }
      [200, { 'Content-Type' => 'text/html' }, %w(hi there)]
    end
    middleware = MyLogger.new(app)
    middleware.call('PATH_INFO' => '/gggg/')
    json = JSON.parse(middleware.stream.string.lines.last)
    expect(json['my_key']).to eq('forty two')
  end

  describe 'post-processing the log data' do
    describe '#filter_attributes' do
      let(:middleware) do
        app = proc do|_env|
          [200, { 'Content-Type' => 'text/html' }, %w(hi there)]
        end
        MyLogger.new(app)
      end
      let(:json) { JSON.parse(middleware.stream.string.lines.last) }

      it 'is invoked with the attribute hash each time a log entry is made' do
        expect(middleware).to receive(:filter_attributes).and_call_original
        middleware.call('PATH_INFO' => '/gggg/')
      end

      context 'without specify any sampler' do
        it 'allows log parameters to be transformed or deleted before writing' do
          expect(middleware).to receive(:filter_attributes) do |attr|
            { how_many_entries: attr.keys.length }
          end
          middleware.call('PATH_INFO' => '/gggg/')
          expect(json['time']).to be_nil
          expect(json['how_many_entries']).to be 9
        end
      end

      context 'configuring the memory and the duration sample' do
        before do
          Jimmy.configure do |config|
            config.samplers = [Jimmy::Samplers::Time, Jimmy::Samplers::Memory]
          end
        end

        it 'allows log parameters to be transformed or deleted before writing' do
          expect(middleware).to receive(:filter_attributes) do |attr|
            { how_many_entries: attr.keys.length }
          end
          middleware.call('PATH_INFO' => '/gggg/')
          expect(json['time']).to be_nil
          expect(json['how_many_entries']).to be 10
        end
      end
    end
  end
end

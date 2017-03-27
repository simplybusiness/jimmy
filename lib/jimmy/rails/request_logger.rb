# Extend the generic one-line-per-request JSON

module Jimmy
  module Rails
    class RequestLogger < SimpleRequestLogger
      def stream
        @stream ||=
          begin
            file_name = ::Rails.root + 'log' + (::Rails.env + '_json.log')
            File.open(file_name, 'a').tap do |file|
              file.sync = true
            end
          end
      end

      def local_address
        @local_address ||= determine_local_ip
      end

      # this address is set based on HTTP headers and so can't actually
      # be relied on.  When correct, however, it is probably more useful than
      # env["REMOTE_ADDR"] which will typically just be that of the next
      # upstream proxy.

      # The functionality in ActionDispatch::RemoteIp::GetIp is
      # presently only available as a middleware, which means we have to
      # invoke it with a rack handler.  This is daft: if you can see a
      # less convoluted way I will gladly take patches
      def client_address(env)
        dummy_handler = proc do |request_env|
          [204, { 'ip' => request_env['action_dispatch.remote_ip'].to_s }]
        end
        _, addr = ActionDispatch::RemoteIp.new(dummy_handler).call(env)
        addr.fetch('ip', '(unknown)')
      end

      def attributes_for_env(env)
        super.merge(local_address: local_address,
                    client_address: client_address(env))
      end

      def filter_attributes(attributes)
        @filter ||= ActionDispatch::Http::ParameterFilter.new(::Rails.application.config.filter_parameters)
        @filter.filter attributes
      end

      private

      # See: http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address/
      def determine_local_ip
        orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

        UDPSocket.open do |s|
          s.connect '64.233.187.99', 1 # Google's IP, which won't be hit anyway
          s.addr.last.chomp
        end
      rescue Errno::ENETUNREACH
        raise unless ::Rails.env.test?
        '127.0.0.1'
      ensure
        Socket.do_not_reverse_lookup = orig
      end
    end
  end
end

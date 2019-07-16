module Jimmy
  class Configuration
    attr_accessor :samplers
    attr_writer :file_path, :logger_stream, :filter_uri, :ip_spoofing_check

    def file_path
      @file_path || default_file_path
    end

    def logger_stream
      @logger_stream ||= File.open(file_path, 'a').tap do |file|
        file.sync = true
      end
    end

    def filter_uri
      @filter_uri || false
    end

    def ip_spoofing_check
      @ip_spoofing_check || false
    end

    def additional_context
      @additional_context || ->(_) { {} }
    end

    def additional_context=(additional_context)
      raise ArgumentError.new("additional_context has been misconfigured. Please supply an object that responds to #call with a single argument. You supplied a #{additional_context.class}: #{additional_context}") if !additional_context.respond_to?(:call) || !additional_context.parameters.one?
      raise ArgumentError.new("additional_context has been misconfigured. Please supply an object that returns a hash.") if !additional_context.call(DummyEnv.new).is_a?(Hash)
      @additional_context = additional_context
    end

    private

    def default_file_path
      ::Rails.root + 'log' + (::Rails.env + '_json.log')
    end
  end

  class DummyEnv < OpenStruct
    def respond_to_missing?
      true
    end

    def method_missing(*_args)
      nil
    end
  end
end

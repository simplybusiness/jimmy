module Jimmy
  class Configuration
    attr_accessor :samplers
    attr_writer :file_path, :logger_stream, :filter_uri, :ip_spoofing_check, :additional_context

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

    private

    def default_file_path
      ::Rails.root + 'log' + (::Rails.env + '_json.log')
    end
  end
end

module Jimmy
  class Configuration

    attr_accessor :samplers
    attr_reader :logger_stream

    def file_path
      @file_path || default_file_path
    end

    def file_path=(path)
      @file_path = path
    end

    def logger_stream
      @logger_stream ||= File.open(file_path, 'a').tap do |file|
        file.sync = true
      end
    end

    private

    def default_file_path
      ::Rails.root + 'log' + (::Rails.env + '_json.log')
    end

  end
end

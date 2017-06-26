module Jimmy
  class Configuration

    attr_accessor :samplers

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

    def logger_stream=(stream)
      @logger_stream = stream
    end

    private

    def default_file_path
      ::Rails.root + 'log' + (::Rails.env + '_json.log')
    end

  end
end

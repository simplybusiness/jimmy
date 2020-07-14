module Jimmy
  class Writer
    def initialize(stream)
      @stream = stream
    end

    def write(entry)
      try_write(log_line_from(entry))
    rescue JSON::GeneratorError => error
      if error.message == 'source sequence is illegal/malformed utf-8'
        converted_entry = force_utf8_encoding_for(entry)
        try_write(log_line_from(converted_entry))
      else
        raise error
      end
    end

    private

    attr_reader :stream

    def try_write(entry)
        stream.write(entry)
    end

    def log_line_from(entry)
      "#{entry.to_json}\n"
    end

    def force_utf8_encoding_for(entry)
      entry = entry.dup
      entry.each do |key, value|
        entry[key] = value.is_a?(String) ? encode_string(value) : value
      end
    end

    def encode_string(string)
      string.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    end

  end
end

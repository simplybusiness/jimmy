module Jimmy
  class Entry < Hash
    def <<(hash)
      self.merge!(hash.try(:to_unsafe_h) || hash)
    end

    def initialize(error_formatter: nil)
      @error_formatter = error_formatter || RubyErrorFormatter.new
    end

    def error(error)
      self.merge!(@error_formatter.attributes_for_error(error))
    end
  end
end

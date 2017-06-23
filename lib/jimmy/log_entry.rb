module Jimmy
  class Entry < Hash

    def initialize(error_formatter: nil)
      @error_formatter = error_formatter || RubyErrorFormatter.new
    end

    def error(error)
      self.merge!(@error_formatter.attributes_for_error(error))
    end
  end
end

module Jimmy
  class Entry < Hash
    def <<(hash)
      self.merge!(hash)
    end

    def error(error)
      self.merge!(attributes_for_error(error))
    end

    private

    def attributes_for_error(error)
      {
          response_code: '500',
          error_class: error.class.name,
          error_message: error.message,
          error_backtrace: error.backtrace.join("\n"),
      }
    end

  end
end

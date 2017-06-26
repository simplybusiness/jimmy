module Jimmy
  class Entry
    class RubyErrorFormatter
      def attributes_for_error(error)
        {
          error_class: error.class.name,
          error_message: error.message,
          error_backtrace: Array(error.backtrace).join("\n"),
        }
      end
    end
  end
end

module Jimmy
  class Entry
    class RailsErrorFormatter
      def attributes_for_error(error)
        { response_code: '500' }.merge!(RubyErrorFormatter.new.attributes_for_error(error))
      end
    end
  end
end

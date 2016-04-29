module Jimmy
  module Samplers
    class Time < Sampler
      def initialize
        @timestamp = ::Time.now.utc
      end

      def collect
        {
          timestamp: timestamp.iso8601(3),
          duration: duration
        }
      end

      private

      attr_reader :timestamp

      def duration
        ::Time.now.utc - timestamp
      end
    end
  end
end

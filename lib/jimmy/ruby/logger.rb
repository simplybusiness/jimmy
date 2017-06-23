# Extend the generic one-line-per-request JSON

module Jimmy
  module Ruby
    class Logger
      include Singleton

      def log(hash)
        entry = Entry.new
        entry.merge!(collect_stats_from(sampler_instances)).merge!(hash)
        log_writer.write(entry)
      end

      private

      def log_writer
        @writer ||= Writer.new(Jimmy.configuration.logger_stream)
      end

      def samplers
        Jimmy.configuration.samplers || [Jimmy::Samplers::Time]
      end

      def sampler_instances
        samplers.map(&:new)
      end

      def collect_stats_from(samplers)
        samplers.inject({}) do |output, sampler|
          output.merge(sampler.collect)
        end
      end
    end
  end
end

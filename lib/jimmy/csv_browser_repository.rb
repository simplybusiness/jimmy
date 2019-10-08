# frozen_string_literal: true

require 'csv'

module Jimmy
  class CSVBrowserRepository
    include Enumerable

    def initialize(csv:)
      @csv = csv
    end

    def preload!
      @browsers ||= browsers_from_csv
    end

    def each(&block)
      (@browsers ||= browsers_from_csv).each(&block)
    end

    private

    def browsers_from_csv
      @csv.yield_self(&parse).map(&to_browser)
    end

    def parse
      ->(csv) { CSV.parse(csv, headers: true, converters: [hash_converter, array_converter]).map(&:to_h) }
    end

    def hash_converter
      ->(value) { value.to_s.start_with?('{') && value.to_s.end_with?('}') ? instance_eval(value) : value }
    end

    def array_converter
      ->(value) { value.to_s.start_with?('[') && value.to_s.end_with?(']') ? instance_eval(value) : value }
    end

    def to_browser
      ->(attrs) { Browser.new(attrs.symbolize_keys) }
    end
  end
end

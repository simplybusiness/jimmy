# frozen_string_literal: true

require 'csv'

module Jimmy
  class BrowserRepository
    def initialize(csv:)
      @browsers = csv.yield_self(&parse).map(&to_browser)
    end

    def find_by(user_agent:)
      @browsers.find { |browser| browser.user_agent == user_agent }
    end

    private

    def parse
      ->(csv) { CSV.parse(csv, headers: true, converters: [hash_converter, array_converter]).map(&:to_h) }
    end

    def to_browser
      ->(attrs) { Browser.new(attrs.symbolize_keys) }
    end

    def hash_converter
      ->(value) { value.to_s.start_with?('{') && value.to_s.end_with?('}') ?  instance_eval(value) : value }
    end

    def array_converter
      ->(value) { value.to_s.start_with?('[') && value.to_s.end_with?(']') ?  instance_eval(value) : value }
    end
  end
end

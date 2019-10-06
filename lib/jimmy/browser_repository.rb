# frozen_string_literal: true

require 'csv'

CSV::Converters[:array] = ->(value) { 
  if value.to_s.start_with?('[') && value.to_s.end_with?(']')
    instance_eval(value)
  else
    value
  end
}

CSV::Converters[:hash] = ->(value) { 
  if value.to_s.start_with?('{') && value.to_s.end_with?('}')
    instance_eval(value)
  else
    value
  end
}

module Jimmy
  class BrowserRepository
    def initialize(csv:)
      @browsers = csv.then(&parse).map(&to_browser)
    end

    def find_by(user_agent:)
      @browsers.find { |browser| browser.user_agent == user_agent }
    end

    def parse
      ->(csv) { CSV.parse(csv, headers: true, converters: [:array, :hash]).map(&:to_h) }
    end

    def to_browser
      ->(attrs) { Browser.new(attrs.symbolize_keys) }
    end
  end
end

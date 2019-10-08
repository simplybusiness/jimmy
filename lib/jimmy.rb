require 'active_support/all'
require 'dry-struct'
require 'jimmy/version'
require 'jimmy/configuration'
require 'jimmy/log_entry'
require 'jimmy/browser'
require 'jimmy/csv_browser_repository'
require 'jimmy/log_entry/ruby_error_formatter'
require 'jimmy/log_entry/rails_error_formatter'
require 'jimmy/writer'
require 'jimmy/samplers/sampler'
require 'jimmy/samplers/time'
require 'jimmy/samplers/memory'
require 'jimmy/simple_request_logger'
require 'jimmy/ruby/logger'
require 'jimmy/rails/request_logger'
require 'jimmy/rails/controller_runtime'

module Jimmy
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.browser_repo
    @browser_repo ||= CSVBrowserRepository.new(csv: File.open(configuration.browser_csv_file_path))
  end
end

ActiveSupport.on_load(:after_initialize) do
  Jimmy.browser_repo.preload!
end

ActiveSupport.on_load(:action_controller) do
  include Jimmy::Rails::ControllerRuntime
end

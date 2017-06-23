require 'active_support/all'
require 'jimmy/version'
require 'jimmy/configuration'
require 'jimmy/log_entry'
require 'jimmy/writer'
require 'jimmy/samplers/sampler'
require 'jimmy/samplers/time'
require 'jimmy/samplers/memory'
require 'jimmy/simple_request_logger'
require 'jimmy/rails/request_logger'
require 'jimmy/rails/controller_runtime'

module Jimmy
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end
end

ActiveSupport.on_load(:action_controller) do
  include Jimmy::Rails::ControllerRuntime
end

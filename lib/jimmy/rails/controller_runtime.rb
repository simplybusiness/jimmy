module Jimmy
  module Rails
    module ControllerRuntime
      extend ActiveSupport::Concern

      included do
        before_filter :log_controller_and_action
      end

      protected

      def log_controller_and_action
        log_entry = request.env['sb.simple_request_logger.entry']
        return unless log_entry

        log_entry << {
          controller: controller_name,
          action: action_name,
          session_id: session[:session_id]
        }
      end
    end
  end
end

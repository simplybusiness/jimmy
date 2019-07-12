# Generic one-line-per-request JSON log as Rack middleware.

require 'json'
require 'cgi'
require 'rack'

module Jimmy
  class SimpleRequestLogger

    def initialize(app, _args = {})
      @next_app = app
      @log_writer = Writer.new(stream)
    end

    def call(env)
      sampler_instances = samplers.map(&:new)
      entry = Jimmy::Entry.new(error_formatter: Entry::RailsErrorFormatter.new)

      response = begin
        @next_app.call(env.merge('sb.simple_request_logger.entry' => entry))
      rescue Exception => error
        error
      end

      entry.merge!(collect_stats_from(sampler_instances))
        .merge!(attributes_for_env(env))

      if response.is_a?(Exception)
        entry.error(response)
      else
        entry.merge!(attributes_for_response(response))
      end

      log_writer.write(filter_attributes(entry))

      raise response if response.is_a?(Exception)
      response
    end

    def stream
      fail NoMethodError, :stream.to_s
    end

    private

    attr_reader :log_writer

    def filter_attributes(attributes)
      attributes
    end

    def parse_body(env)
      content_type = env['CONTENT_TYPE']
      if (env['CONTENT_LENGTH'] || '0').to_i > 0
        if (content_type.nil? && (env['REQUEST_METHOD'] == 'POST')) ||
          content_type == 'application/x-www-form-urlencoded'
          Rack::Request.new(env.dup).POST
        end
      end
    end

    def attributes_for_env(env)
      request_id = env['HTTP_X_REQUEST_ID']
      attributes = {
        remote_address: env['REMOTE_ADDR'],
        uri: env['ORIGINAL_FULLPATH'],
        user_agent: env['HTTP_USER_AGENT'],
        referer: env['HTTP_REFERER'],
        query_params: CGI.parse(env['QUERY_STRING'] || ''),
        request_method: env['REQUEST_METHOD']
      }
      parsed_body = parse_body(env)
      attributes.merge!(body_params: parsed_body) if parsed_body

      # X-Request-Id may be a request header (if if has been set by an
      # upstream server or loadbalancer or reverse proxy) or a response
      # header, if it has been set internally by the
      # ActionDispatch::RequestId middleware.  Or neither, if you're not
      # using a proxy and don't have that middleware
      attributes.merge!(request_id: request_id) if request_id

      # X-Amzn-Trace-Id is present for request incoming from Amazon ELB
      # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-request-tracing.html
      attributes.merge!(x_amzn_trace_id: env['HTTP_X_AMZN_TRACE_ID']) if env['HTTP_X_AMZN_TRACE_ID']
      
      # Cloudflare adds the true client ip header to help differentiate from
      # proxies. The trust score is provided as an indicator for malicous
      # activity. While traffic can bypass Cloudflare I have added the
      # x-forwarded-for header in so we can view and block clients that by pass
      # the service.
      attributes.merge!(true_client_ip: env['HTTP_TRUE_CLIENT_IP']) if env['HTTP_TRUE_CLIENT_IP']
      attributes.merge!(cflare_trust_score: env['HTTP_CF_TRUST_SCORE']) if env['HTTP_CF_TRUST_SCORE']
      attributes.merge!(x_forwarded_for: env['HTTP_X_FORWARDED_FOR']) if env['HTTP_X_FORWARDED_FOR']

      attributes.merge!(user_id: env['USER_ID']) if env['USER_ID']
      attributes.merge!(external_user_id: env['EXTERNAL_USER_ID']) if env['EXTERNAL_USER_ID']

      attributes
    end

    def attributes_for_response(response)
      response_code, response_headers, response_body = *response
      request_id = response_headers['X-Request-Id']

      attributes = {
        response_code: response_code
      }
      attributes.merge!(request_id: request_id) if request_id.present?

      attributes
    end

    def samplers
      Jimmy.configuration.samplers || [Jimmy::Samplers::Time]
    end

    def collect_stats_from(samplers)
      samplers.inject({}) do |output, sampler|
        output.merge(sampler.collect)
      end
    end
  end
end

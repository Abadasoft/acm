require 'acm/errors'
require 'acm_controller'
require 'sinatra/base'
require 'json'
require 'net/http'

module ACM

  module Controller

    class ApiController < Sinatra::Base

      def initialize
        super
        @logger = Config.logger
        @logger.debug("ACM ApiController is up")
      end

      load 'routes/route_objects.rb'

      configure do
        set(:show_exceptions, false)
        set(:raise_errors, false)
        set(:dump_errors, true)
      end

      error do
        content_type 'application/json', :charset => 'utf-8'

        @logger.debug("Reached error handler")
        exception = request.env["sinatra.error"]
        if exception.kind_of?(ACMError)
          @logger.debug("Request failed with response code: #{exception.response_code} error code: " +
                           "#{exception.error_code} error: #{exception.message}")
          status(exception.response_code)
          error_payload                = Hash.new
          error_payload['code']        = exception.error_code
          error_payload['description'] = exception.message
          #TODO: Handle meta and uri. Exception class to contain to_json
          Yajl::Encoder.encode(error_payload)
        else
          msg = ["#{exception.class} - #{exception.message}"]
          @logger.warn(msg.join("\n"))
          status(500)
        end
      end

      not_found do
        content_type 'application/json', :charset => 'utf-8'

        @logger.debug("Reached not_found handler")
        status(404)
        error_payload                = Hash.new
        error_payload['code']        = ACM::ObjectNotFound.new("").error_code
        error_payload['description'] = "The resource was not found"
        #TODO: Handle meta and uri
        Yajl::Encoder.encode(error_payload)
      end

    end

  end

end

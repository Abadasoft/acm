require 'acm/errors'
require 'acm_controller'
require 'acm/routes/object_controller'
require 'acm/routes/permission_set_controller'
require 'acm/routes/group_controller'
require 'acm/routes/access_controller'
require 'acm/routes/user_controller'
require 'acm/services/object_service'
require 'acm/services/user_service'
require 'acm/services/group_service'
require 'acm/services/permission_set_service'
require 'acm/services/access_control_service'
require 'sinatra/base'
require 'json'
require 'net/http'

module ACM::Controller

  #Sinatra controller that responds to all ACM requests
  #For code organization purposes, it's broken up into
  #multiple files, one for each set of routes. See routes/
  class ApiController < Sinatra::Base

    def initialize
      super
      @logger = ACM::Config.logger

      @object_service = ACM::Services::ObjectService.new()
      @user_service = ACM::Services::UserService.new()
      @group_service = ACM::Services::GroupService.new()
      @permission_set_service = ACM::Services::PermissionSetService.new()
      @access_control_service = ACM::Services::AccessControlService.new()

      @logger.debug("ACM ApiController is up")
    end

    configure do
      set(:show_exceptions, false)
      set(:raise_errors, false)
      set(:dump_errors, false)
    end

    #Main error handler for the ACM
    error do
      content_type 'application/json', :charset => 'utf-8'

      exception = request.env["sinatra.error"]
      @logger.debug("Reached error handler #{exception.inspect}")
      if exception.kind_of?(ACM::ACMError)
        @logger.error("Request failed with response code: #{exception.response_code} error code: " +
                         "#{exception.error_code} error: #{exception.message}")
        status(exception.response_code)
        error_payload                = Hash.new
        error_payload['code']        = exception.error_code
        error_payload['description'] = exception.message
        error_payload['schema'] = "urn:acm:schemas:1.0"
        #TODO: Handle meta and uri. Exception class to contain to_json
        Yajl::Encoder.encode(error_payload)
      else
        msg = ["#{exception.class} - #{exception.message}"]
        @logger.error(msg.join("\n"))
        status(500)
      end
    end

    #not found sinatra handler for the ACM. Handles routes that cannot
    #be found and avoids the standard sinatra response
    not_found do
      content_type 'application/json', :charset => 'utf-8'

      @logger.debug("Reached not_found handler")
      status(404)
      error_payload                = Hash.new
      error_payload['code']        = ACM::ObjectNotFound.new("").error_code
      error_payload['description'] = "The object was not found"
      error_payload['schema'] = "urn:acm:schemas:1.0"
      #TODO: Handle meta and uri
      Yajl::Encoder.encode(error_payload)
    end

  end

end

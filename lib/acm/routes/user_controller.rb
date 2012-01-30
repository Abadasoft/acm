require 'sinatra/base'

module ACM::Controller

  class ApiController < Sinatra::Base

    post '/users/:user_id' do
      content_type 'application/json', :charset => 'utf-8', :schema => ACM::Config.default_schema_version
      @logger.debug("POST request for /users/#{params[:user_id]}")

      response = @user_service.create_user(:id => params[:user_id])
      @logger.debug("Response is #{response.inspect}")

      response
    end

    get '/users/:user_id' do
      content_type 'application/json', :charset => 'utf-8', :schema => ACM::Config.default_schema_version
      @logger.debug("GET request for /users/#{params[:user_id]}")

      response = @user_service.get_user_info(params[:user_id])
      @logger.debug("Response is #{response.inspect}")

      response
    end

  end

end

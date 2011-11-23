require File.expand_path("../../spec_helper", __FILE__)

require "rack/test"
require "json"

describe ACM::Controller::RackController do
  include Rack::Test::Methods

  def app
    @app ||= ACM::Controller::RackController.new
  end

  before(:all) do
    @logger = ACM::Config.logger
  end

  describe "when sending an invalid request for group creation" do

    it "should respond with an error on an incorrectly formatted request" do
      @logger = ACM::Config.logger
      basic_authorize "admin", "password"

      post "/groups", {}, { "CONTENT_TYPE" => "application/json", :input => "group_data" }
      @logger.debug("post /groups last response #{last_response.inspect}")
      last_response.status.should eql(400)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should be_nil

      body[:code].should eql(1001)
      body[:description].should include("Invalid request")

    end

    it "should respond with an error on an empty request" do
      @logger = ACM::Config.logger
      basic_authorize "admin", "password"

      post "/groups", {}, { "CONTENT_TYPE" => "application/json", :input => nil }
      @logger.debug("post /groups last response #{last_response.inspect}")
      last_response.status.should eql(400)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should be_nil

      body[:code].should eql(1001)
      body[:description].should include("Invalid request")

    end

  end

  describe "when creating a new group" do

    before(:each) do
      @user1 = SecureRandom.uuid
      @user2 = SecureRandom.uuid
      @user3 = SecureRandom.uuid
      @user4 = SecureRandom.uuid

      @group1 = SecureRandom.uuid

      @user_service = ACM::Services::UserService.new()
      @group_service = ACM::Services::GroupService.new()

    end

    it "should create the correct group" do
      basic_authorize "admin", "password"

      group_data = {
        :id => @group1,
        :additional_info => "Developer group",
        :members => [@user1, @user2, @user3, @user4]
      }

      post "/groups", {}, { "CONTENT_TYPE" => "application/json", :input => group_data.to_json() }
      @logger.debug("post /groups last response #{last_response.inspect}")
      last_response.status.should eql(200)
      last_response.original_headers["Content-Type"].should eql("application/json;charset=utf-8")
      last_response.original_headers["Content-Length"].should_not eql("0")

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)
      last_response.original_headers["Location"].should eql("http://example.org/groups/#{body[:id]}")

      body[:id].to_s.should eql(group_data[:id].to_s)
      body[:members].sort().should eql(group_data[:members].sort())
      body[:additionalInfo].should eql(group_data[:additionalInfo])
      body[:meta][:created].should_not be_nil
      body[:meta][:updated].should_not be_nil
      body[:meta][:schema].should eql("urn:acm:schemas:1.0")

    end

    it "should not create a duplicate group" do
      basic_authorize "admin", "password"

      group_data = {
        :id => @group1,
        :additional_info => "Developer group",
        :members => [@user1, @user2, @user3, @user4]
      }

      post "/groups", {}, { "CONTENT_TYPE" => "application/json", :input => group_data.to_json() }
      @logger.debug("post /groups last response #{last_response.inspect}")
      last_response.status.should eql(200)

      post "/groups", {}, { "CONTENT_TYPE" => "application/json", :input => group_data.to_json() }
      @logger.debug("post /groups last response #{last_response.inspect}")
      last_response.status.should eql(400)
      last_response.original_headers["Location"].should be_nil

    end

    it "should not create group with the same id as a user" do
      basic_authorize "admin", "password"

      group_data = {
        :id => @group1,
        :additional_info => "Developer group",
        :members => [@user1, @user2, @user3, @user4]
      }

      post "/groups", {}, { "CONTENT_TYPE" => "application/json", :input => group_data.to_json() }
      @logger.debug("post /groups last response #{last_response.inspect}")
      last_response.status.should eql(200)

      group_data = {
        :id => @user1,
        :additional_info => "Developer group",
        :members => [@user1, @user2, @user3, @user4]
      }

      post "/groups", {}, { "CONTENT_TYPE" => "application/json", :input => group_data.to_json() }
      @logger.debug("post /groups last response #{last_response.inspect}")
      last_response.status.should eql(400)
      last_response.original_headers["Location"].should be_nil

    end

    it "should not add nil members to the group" do
      basic_authorize "admin", "password"

      group_data = {
        :id => @group1,
        :additional_info => "Developer group",
        :members => [nil, nil]
      }

      post "/groups", {}, { "CONTENT_TYPE" => "application/json", :input => group_data.to_json() }
      @logger.debug("post /groups last response #{last_response.inspect}")
      last_response.status.should eql(200)

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)

      body[:id].to_s.should eql(group_data[:id].to_s)
      body[:members].should be_nil
      body[:additionalInfo].should eql(group_data[:additionalInfo])
      body[:meta][:created].should_not be_nil
      body[:meta][:updated].should_not be_nil
      body[:meta][:schema].should eql("urn:acm:schemas:1.0")

    end

  end

  describe "when requesting a group" do

    before(:each) do
      @user1 = SecureRandom.uuid
      @user2 = SecureRandom.uuid
      @user3 = SecureRandom.uuid
      @user4 = SecureRandom.uuid

      @group1 = SecureRandom.uuid

      @user_service = ACM::Services::UserService.new()
      @group_service = ACM::Services::GroupService.new()

    end


    it "should return the group requested" do
      basic_authorize "admin", "password"

      group_data = {
        :id => @group1,
        :additional_info => "Developer group",
        :members => [@user1, @user2, @user3, @user4]
      }

      post "/groups", {}, { "CONTENT_TYPE" => "application/json", :input => group_data.to_json() }
      @logger.debug("post /groups last response #{last_response.inspect}")
      last_response.status.should eql(200)

      get "/groups/#{@group1}", {}, { "CONTENT_TYPE" => "application/json"}
      @logger.debug("get /groups last response #{last_response.inspect}")
      last_response.status.should eql(200)
      last_response.original_headers["Location"].should be_nil

      body = Yajl::Parser.parse(last_response.body, :symbolize_keys => true)

      body[:id].to_s.should eql(group_data[:id].to_s)
      body[:members].sort().should eql(group_data[:members].sort())
      body[:additionalInfo].should eql(group_data[:additionalInfo])
      body[:meta][:created].should_not be_nil
      body[:meta][:updated].should_not be_nil
      body[:meta][:schema].should eql("urn:acm:schemas:1.0")

    end

    it "should return an error if the group does not exist" do
      basic_authorize "admin", "password"

      get "/groups/12345", {}, { "CONTENT_TYPE" => "application/json"}
      @logger.debug("get /groups last response #{last_response.inspect}")
      last_response.status.should eql(404)

    end

  end

end

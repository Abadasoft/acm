require 'acm/services/acm_service'
require 'acm/models/subjects'
require 'acm/models/members'

module ACM::Services

  class GroupService < ACMService

    def initialize
      super

      @user_service = ACM::Services::UserService.new()
    end

    def create_group(opts = {})

      group = ACM::Models::Subjects.new(
        :immutable_id => !opts[:id].nil? ? opts[:id] : SecureRandom.uuid(),
        :type => :group.to_s,
        :additional_info => !opts[:additional_info].nil? ? opts[:additional_info] : nil
      )

      ACM::Config.db.transaction do
        begin
          existing_group = ACM::Models::Subjects.filter(:immutable_id => group.immutable_id).first()
          if(existing_group.nil?)
            group.save
          else
            @logger.error("Group id #{existing_group.immutable_id} already used")
            raise ACM::InvalidRequest.new("Group id #{existing_group.immutable_id} already used")
          end

          if(!opts[:members].nil?)
            members = opts[:members]
            if(members.kind_of?(Array))
              members.each {|member|
                if(!member.nil?)
                  begin
                    user = ACM::Models::Subjects.filter(:immutable_id => member).first()
                    if(user.nil?)
                      @logger.debug("Could not find user #{member}. Creating the user")
                      user = ACM::Models::Subjects.new(:immutable_id => member, :type => :user.to_s)
                      user.save
                    end
                    group.add_member(:user_id => user.id)
                  end
                end
              }
            else
              @logger.error("Failed to create group. members must be an array")
              raise ACM::InvalidRequest.new("Failed to create group. members must be an array")
            end
          end
        rescue => e
          if e.kind_of?(ACM::ACMError)
            raise e
          else
            @logger.info("Failed to create a user #{e}")
            @logger.debug("Failed to create a user #{e.backtrace.inspect}")
            raise ACM::SystemInternalError.new()
          end
        end
      end

      group.to_json()
    end

    def find_group(group_id)
      @logger.debug("find_group parameters #{group_id.inspect}")
      group = ACM::Models::Subjects.filter(:immutable_id => group_id, :type => :group.to_s).first()

      if(group.nil?)
        @logger.error("Could not group user with id #{group_id.inspect}")
        raise ACM::ObjectNotFound.new("#{group_id.inspect}")
      else
        @logger.debug("Found group #{group.inspect}")
      end

      group.to_json()
    end

    def add_user_to_group(group_id, user_id)
      @logger.debug("find_group parameters #{group_id.inspect}")
      group = ACM::Models::Subjects.filter(:immutable_id => group_id, :type => :group.to_s).first()

      if(group.nil?)
        @logger.error("Could not group user with id #{group_id.inspect}")
        raise ACM::ObjectNotFound.new("#{group_id.inspect}")
      else
        @logger.debug("Found group #{group.inspect}")
      end

      user_json = nil
      begin
        user_json = @user_service.find_user(user_id)
      rescue => e
        if(e.kind_of?(ACM::ObjectNotFound))
          @logger.debug("Could not find user #{user_id}. Creating the user")
          user_json = @user_service.create_user(:id => user_id)
        else
          @logger.error("Internal error #{e.message}")
          raise ACM::SystemInternalError.new()
        end
      end

      user = Yajl::Parser.parse(user_json, :symbolize_keys => true)

      #Is the user already a member of the group?
      group_members = group.members_dataset.filter(:user_id => user[:id]).all()
      @logger.debug("Existing group members #{group_members.inspect}")
      if(group_members.nil? || group_members.size() == 0)
        user = ACM::Models::Subjects.filter(:immutable_id => user_id, :type => :user.to_s).first()
        @logger.debug("new user #{user.id} group #{group.id}")
        group.add_member(:user_id => user.id)
      end

      group = ACM::Models::Subjects.filter(:immutable_id => group_id, :type => :group.to_s).first()
      @logger.debug("Updated group #{group.inspect}")
      group.to_json
    end

    def delete_group(group_id)
      @logger.debug("delete parameters #{group_id.inspect}")
      group = ACM::Models::Subjects.filter(:immutable_id => group_id, :type => :group.to_s).first()

      if(group.nil?)
        @logger.error("Could not find group with id #{group_id.inspect}")
        raise ACM::ObjectNotFound.new("#{group_id.inspect}")
      else
        @logger.debug("Found group #{group.inspect}")
      end

      ACM::Config.db.transaction do
        group_members = group.members
        group_members.each { |group_member|
          group_member.delete
        }

        group.remove_all_access_control_entries

        #TODO: Delete the associated object

        group.delete
        nil
      end
    end

  end

end

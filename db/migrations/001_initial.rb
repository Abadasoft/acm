Sequel.migration do
  up do
    create_table :objects do
      primary_key   :id
      string         :immutable_id, :null => false, :unique => true
      foreign_key   :object_type_id, :object_types
      string         :name
      text          :metadata_json

      time          :created_at, :null => false
      time          :last_updated_at, :null => false

    end

    create_table :object_types do
      primary_key   :id
      string          :name, :null => false, :unique => true

      time          :created_at, :null => false
      time          :last_updated_at, :null => false

    end

    create_table :permissions do
      primary_key   :id
      foreign_key   :object_type_id, :object_types
      string          :name, :null => false

      time          :created_at, :null => false
      time          :last_updated_at, :null => false

      unique        ([:object_type_id, :name])

    end

    create_table :access_control_entities do
      primary_key   :id
      foreign_key   :object_id, :objects
      foreign_key   :permission_id, :permissions
      foreign_key   :group_id, :groups

      time          :created_at, :null => false
      time          :last_updated_at, :null => false

      unique        ([:object_id, :group_id, :permission_id])
    end

    create_table :groups do
      primary_key   :id
      string         :immutable_id, :null => false, :unique => true
      foreign_key   :object_id, :objects
      string         :name

      time          :created_at, :null => false
      time          :last_updated_at, :null => false
    end

    create_table :members do
      primary_key   :id
      foreign_key   :group_id, :groups
      integer         :user_id

      time          :created_at, :null => false
      time          :last_updated_at, :null => false
    end

  end

  down do
    drop_table    :members
    drop_table    :groups
    drop_table    :access_control_entities
    drop_table    :permissions
    drop_table    :objects
    drop_table    :object_types

  end
end

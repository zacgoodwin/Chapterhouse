# frozen_string_literal: true

class DropActiveBotObjects < ActiveRecord::Migration[8.1]
  def up
    safety_assured { drop_table :active_bot_objects }
  end

  def down
    create_table :active_bot_objects, id: :uuid do |t|
      t.string :source, null: false
      t.string :object, null: false
      t.uuid :user_id, null: false
      t.jsonb :info, null: false, default: {}
      t.timestamps
    end
    add_index :active_bot_objects, %i[user_id source object], unique: true
  end
end

class CreateHomebrewSubclasses < ActiveRecord::Migration[8.0]
  def change
    create_table :homebrew_subclasses, id: :uuid, comment: 'Custom subclasses' do |t|
      t.uuid :user_id, null: false
      t.string :class_name, null: false, comment: 'Class name or custom class ID'
      t.string :type, null: false, comment: 'Game system association'
      t.string :name, null: false
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end
    add_index :homebrew_subclasses, :user_id
  end
end

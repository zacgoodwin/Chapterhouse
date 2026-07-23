class CreateHomebrewSpecialities < ActiveRecord::Migration[8.0]
  def change
    create_table :homebrew_specialities, id: :uuid, comment: 'Custom classes' do |t|
      t.uuid :user_id, null: false
      t.string :type, null: false, comment: "Game system association"
      t.string :name, null: false
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end
    add_index :homebrew_specialities, :user_id
  end
end

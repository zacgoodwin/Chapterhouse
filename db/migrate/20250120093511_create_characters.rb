class CreateCharacters < ActiveRecord::Migration[8.0]
  def change
    create_table :characters, id: :uuid, comment: 'Characters' do |t|
      t.string :type, null: false, comment: 'Game system the character was created for'
      t.uuid :user_id, null: false
      t.string :name, null: false
      t.jsonb :data, null: false, default: {}, comment: 'Character properties'
      t.timestamps
    end
    add_index :characters, :user_id
  end
end

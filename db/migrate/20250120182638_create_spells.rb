class CreateSpells < ActiveRecord::Migration[8.0]
  def change
    create_table :spells, id: :uuid, comment: 'Spells' do |t|
      t.string :type, null: false
      t.jsonb :name, null: false, default: {}
      t.jsonb :data, null: false, default: {}, comment: 'Spell properties'
      t.timestamps
    end
  end
end

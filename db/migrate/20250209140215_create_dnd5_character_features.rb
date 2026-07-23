class CreateDnd5CharacterFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :dnd5_character_features, id: :uuid, comment: 'Race/class features' do |t|
      t.string :slug, null: false
      t.jsonb :title, null: false, default: {}
      t.jsonb :description, null: false, default: {}
      t.integer :origin, limit: 1, null: false, comment: 'Feature applicability type, race/subrace/class/subclass'
      t.string :origin_value, null: false, comment: 'Feature applicability value'
      t.integer :level, limit: 1, null: false
      t.integer :kind, limit: 1, null: false
      t.string :options_type, comment: 'Selection data for kind CHOOSE_FROM'
      t.string :options, array: true, comment: 'Options list'
      t.string :visible, null: false, comment: 'Whether the feature bonus is available'
      t.jsonb :eval_variables, null: false, default: {}, comment: 'Evaluated variables'
      t.timestamps
    end
  end
end

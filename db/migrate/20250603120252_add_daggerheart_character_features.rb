class AddDaggerheartCharacterFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :daggerheart_character_features, id: :uuid do |t|
      t.string :slug, null: false
      t.jsonb :title, null: false, default: {}
      t.jsonb :description, null: false, default: {}
      t.integer :origin, limit: 1, null: false, comment: 'Feature applicability type'
      t.string :origin_value, null: false, comment: 'Feature applicability value'
      t.integer :kind, limit: 1, null: false
      t.string :visible, null: false, comment: 'Whether the feature bonus is available'
      t.jsonb :description_eval_variables, null: false, default: {}, comment: 'Evaluated variables for description'
      t.integer :limit_refresh, limit: 1, comment: 'Event that refreshes the limit'
      t.string :exclude, array: true, comment: 'Replaced features'
      t.timestamps
    end
  end
end

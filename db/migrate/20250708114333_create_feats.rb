class CreateFeats < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    create_table :feats, id: :uuid, comment: 'Feats' do |t|
      t.string :type, null: false
      t.string :slug, null: false
      t.jsonb :title, null: false, default: {}
      t.jsonb :description, null: false, default: {}
      t.integer :origin, limit: 1, null: false, comment: 'Feat applicability type'
      t.string :origin_value, null: false, comment: 'Feat applicability value'
      t.integer :kind, limit: 1, null: false
      t.integer :limit_refresh, limit: 1, comment: 'Event that refreshes the limit'
      t.string :exclude, array: true, comment: 'Replaced feats'
      t.jsonb :options, comment: 'Selection options'
      t.jsonb :conditions, null: false, default: {}, comment: 'Feat availability conditions'
      t.jsonb :description_eval_variables, null: false, default: {}, comment: 'Evaluated variables for description'
      t.jsonb :eval_variables, null: false, default: {}, comment: 'Evaluated variables'
      t.timestamps
    end

    create_table :character_feats, id: :uuid, comment: 'Character feats' do |t|
      t.uuid :character_id, null: false
      t.uuid :feat_id, null: false
      t.integer :left_count, comment: 'Remaining uses count'
      t.jsonb :value, comment: 'Selected feat options or entered text'
      t.timestamps
    end

    add_index :character_feats, [:character_id, :feat_id], unique: true
  end
end

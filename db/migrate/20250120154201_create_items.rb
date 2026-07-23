class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items, id: :uuid, comment: 'Items' do |t|
      t.string :type, null: false
      t.string :kind, null: false, comment: 'Item kind'
      t.jsonb :name, null: false, default: {}
      t.jsonb :data, null: false, default: {}, comment: 'Item properties'
      t.timestamps
    end
  end
end

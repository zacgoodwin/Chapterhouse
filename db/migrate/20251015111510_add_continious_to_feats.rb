class AddContiniousToFeats < ActiveRecord::Migration[8.0]
  def change
    add_column :feats, :continious, :boolean, default: false, comment: 'Whether the feat has a toggleable effect'
    add_column :character_feats, :active, :boolean, default: false, comment: 'Whether the feat effect is enabled'
  end
end

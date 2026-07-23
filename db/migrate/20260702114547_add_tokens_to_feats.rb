class AddTokensToFeats < ActiveRecord::Migration[8.1]
  def change
    add_column :feats, :tokens, :jsonb, comment: 'Token settings for feats'
    add_column :character_feats, :tokens, :integer, comment: 'Current token count'
  end
end

# frozen_string_literal: true

# Campaign chapter feeds the TLC level-cap soft warning (Players Guide Table 2:
# ch8 -> level 12 ... ch16 -> 20) computed in Tlc::Warnings. Nullable and purely
# additive: existing campaigns keep NULL and raise no warning, and a rollback of
# the TLC work can leave the column in place (plan §Rollback posture).
#
# C6 (#22) plans the same column for the rank/chapter work; C7 needed it first to
# make its own acceptance case real rather than stubbed. The guard makes either
# merge order a no-op for the loser.
class AddChapterToCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :campaigns, :chapter, :integer unless column_exists?(:campaigns, :chapter)
  end
end

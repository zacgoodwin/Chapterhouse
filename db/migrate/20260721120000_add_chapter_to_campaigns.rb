# frozen_string_literal: true

# Campaign chapter feeds the TLC level-cap soft warning (Players Guide Table 2:
# ch8 -> level 12 ... ch16 -> 20) computed in Tlc::Warnings. Nullable and purely
# additive: existing campaigns keep NULL and raise no warning.
#
# `if_not_exists: true` (not a `column_exists?` guard) so the migration stays
# reversible: the guard form skips add_column in the REVERTING direction too,
# which makes `db:rollback` print "reverted", drop the schema_migrations row and
# leave the column behind. Postgres does the check here, and change/rollback
# both invert cleanly.
#
# The flag protects THIS file only. C6 (#22) plans the same column: if it also
# ships an add_column, `bin/rails db:migrate` -- the Fly release_command on every
# deploy -- fails for whichever lands second, with DuplicateMigrationNameError if
# the class name matches and PG::DuplicateColumn if it does not. #22 must drop
# its duplicate step, not rely on a guard here.
class AddChapterToCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :campaigns, :chapter, :integer, if_not_exists: true
  end
end

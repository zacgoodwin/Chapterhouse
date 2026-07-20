# frozen_string_literal: true

# Provenance marker for system-granted custom_resources (ticket C8: TLC
# subclass resource pools). Player-created resources (ResourcesContext::AddCommand,
# the "Custom Resources" UI) leave this nil; CharactersContext::Tlc::RefreshResources
# stamps it with the resources.json definition slug so it can find-or-create
# idempotently on subclass attach and delete cleanly on subclass detach, without
# touching or colliding with a player's own same-named resource. Additive,
# nullable, zero-downtime.
class AddOriginSlugToCustomResources < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :custom_resources, :origin_slug, :string
    add_index :custom_resources, :origin_slug, algorithm: :concurrently
  end
end

# frozen_string_literal: true

# WIDENED DELIBERATELY from a TLC-only attach to the shared-content union (#76).
# The regression: a TLC character got ZERO features because feats() used the
# strict ::Tlc::Feat scope while db/data/tlc/* seeds zero rows -- every shared
# species/class feature lives as a Dnd2024::Feat row (B1/B4 unmerged). The
# client-side deep-merge shares the OPTIONS, so the server must share the
# FEATURES: feats() now queries ::Feat.tlc_content, the same union the spells
# path uses at tlc/create_command.rb:110. These expectations pin that union; the
# TLC-only case proves the strict path still works alongside it.
describe CharactersContext::Tlc::RefreshFeats do
  subject(:service_call) { described_class.new.call(character: Tlc::Character.find(character.id)) }

  # Human bard, level 4: feats() queries origin_value IN ['human', 'bard', id].
  let!(:character) { create :character, :tlc }

  # Shared rows stored as Dnd2024::Feat -- invisible to a strict ::Tlc::Feat
  # scope, which is exactly the bug. Blank conditions (schema default {}) attach
  # unconditionally.
  let!(:shared_species_trait) { create :feat, :dnd2024, origin: 0, origin_value: 'human', slug: 'resourceful' }
  # limit_refresh 1 == long_rest in the Dnd2024::Feat enum (see below).
  let!(:shared_class_feature) {
    create :feat, :dnd2024, origin: 1, origin_value: 'bard', slug: 'bardic_die', limit_refresh: 1
  }

  # MUTATION GUARD (last AC): revert feats() to ::Tlc::Feat and this goes RED --
  # the Dnd2024::Feat rows stop being queried, so nothing shared attaches.
  it 'attaches the shared dnd2024 species trait and class feature to a TLC character', :aggregate_failures do
    service_call

    attached = character.feats.pluck(:feat_id)
    expect(attached).to include(shared_species_trait.id)
    expect(attached).to include(shared_class_feature.id)
  end

  it 'attaches a TLC-only species trait alongside the shared dnd2024 rows', :aggregate_failures do
    tlc_only = create :feat, :tlc, origin: 0, origin_value: 'human', slug: 'tlc-warden-sense'

    service_call

    attached = character.feats.pluck(:feat_id)
    expect(attached).to include(tlc_only.id)
    expect(attached).to include(shared_species_trait.id)
    expect(attached).to include(shared_class_feature.id)
  end

  # MUTATION GUARD (last AC): drop `type` from REQUIRED_ATTRIBUTES and this goes
  # RED. The base-Feat union can only resolve STI when `type` is selected;
  # without it, rows load as base `Feat` and add_new_available_feats raises
  # NoMethodError on Feat.limit_refreshes (base Feat declares no enum). The
  # integer copied onto Character::Feat (1, via Dnd2024::Feat.limit_refreshes)
  # is the proof item.class resolved to the concrete subclass, not base Feat.
  it 'resolves union rows to their real STI subclass and copies the limit_refresh enum', :aggregate_failures do
    expect { service_call }.not_to raise_error

    dnd2024_row = character.feats.find_by(feat_id: shared_class_feature.id)
    expect(dnd2024_row).to be_present
    expect(dnd2024_row.limit_refresh).to eq 1
  end

  # match_by_level? still filters across the union: a bard feature gated above
  # the character's bard level (4) must not attach even though origin_value matches.
  it 'applies match_by_level? across the union', :aggregate_failures do
    gated_out = create :feat, :dnd2024, origin: 1, origin_value: 'bard', slug: 'above-level', conditions: { level: 5 }
    gated_in = create :feat, :dnd2024, origin: 1, origin_value: 'bard', slug: 'at-level', conditions: { level: 4 }

    service_call

    attached = character.feats.pluck(:feat_id)
    expect(attached).to include(gated_in.id)
    expect(attached).not_to include(gated_out.id)
  end
end

# frozen_string_literal: true

module Tlc
  # Visibility + verified meta for TLC content rows (Tlc::Feat/Item/Spell).
  #
  # Both flags live in the row's jsonb meta column (`info` for feats/items,
  # `data` for spells), exactly where Tlc::Seeder folds them — NOT in new
  # columns (ticket step 1: "migration-free data placement, follow whichever the
  # existing content models use for comparable flags"). Each including class
  # declares its meta + display-name columns via `tlc_content`.
  #
  # Visibility semantics (plan §Resolved questions; the 4-value set resolving the
  # design doc's 3-way disagreement):
  #   public     addable and searchable (the default when unset).
  #   locked     not addable, not searchable. Existing character holdings are
  #              untouched — the scopes govern only what the options path OFFERS.
  #   deprecated not addable/searchable. Removal-with-replacement of existing
  #              holdings is deferred (label only at this stage).
  #   hidden     absent from the browse list and from partial search; surfaces
  #              ONLY on an exact name/slug match.
  #
  # The `.addable` / `.searchable` scopes are the seam the parked C5 options +
  # D2 list tickets consume; this ticket ships them at the query layer with specs.
  module ContentFlags
    extend ActiveSupport::Concern

    VISIBILITIES = %w[public locked deprecated hidden].freeze
    DEFAULT_VISIBILITY = 'public'

    included do
      validates :visibility, inclusion: { in: VISIBILITIES }
    end

    class_methods do
      # Declare the jsonb meta column and the display-name jsonb column for this
      # STI class. Called once in each Tlc content model's body.
      def tlc_content(meta:, name:)
        @tlc_meta_column = meta.to_s
        @tlc_name_column = name.to_s
      end

      def meta_column = @tlc_meta_column
      def name_column = @tlc_name_column

      # Options browse list: only public rows are offered.
      def addable
        where("COALESCE(#{meta_column} ->> 'visibility', '#{DEFAULT_VISIBILITY}') = '#{DEFAULT_VISIBILITY}'")
      end

      # Search by term: public rows match on a partial (case-insensitive) name or
      # slug; hidden rows surface ONLY on an exact match; locked/deprecated never
      # surface. `term` is bound, so it is safe against injection.
      def searchable(term)
        where(
          "(COALESCE(#{meta_column} ->> 'visibility', '#{DEFAULT_VISIBILITY}') = '#{DEFAULT_VISIBILITY}' " \
          "  AND (slug ILIKE :like OR #{name_column} ->> 'en' ILIKE :like)) " \
          "OR (#{meta_column} ->> 'visibility' = 'hidden' " \
          "  AND (slug = :exact OR LOWER(#{name_column} ->> 'en') = LOWER(:exact)))",
          like: "%#{sanitize_sql_like(term.to_s)}%", exact: term.to_s
        )
      end

      # Verification queue filter (adminbook `?verified=false`). `verified`
      # defaults to true (Tlc::Seeder), so only rows explicitly gated read false.
      def where_verified(value)
        where("COALESCE((#{meta_column} ->> 'verified')::boolean, true) = ?", value)
      end
    end

    def visibility
      meta['visibility'] || DEFAULT_VISIBILITY
    end

    def visibility=(value)
      write_meta('visibility', value)
    end

    def verified?
      meta.fetch('verified', true)
    end
    alias verified verified?

    def verified=(value)
      write_meta('verified', ActiveModel::Type::Boolean.new.cast(value))
    end

    private

    def meta
      self[self.class.meta_column] || {}
    end

    # Reassign a fresh hash so ActiveRecord marks the jsonb attribute dirty
    # (in-place mutation of a jsonb hash does not always trip change tracking).
    def write_meta(key, value)
      self[self.class.meta_column] = meta.merge(key => value)
    end
  end
end

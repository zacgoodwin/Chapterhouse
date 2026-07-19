# frozen_string_literal: true

class Channel < ApplicationRecord
  OWLBEAR = 'owlbear'

  belongs_to :campaign, optional: true

  enum :provider, { OWLBEAR => 1 }
end

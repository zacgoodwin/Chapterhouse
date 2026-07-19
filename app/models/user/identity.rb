# frozen_string_literal: true

class User
  class Identity < ApplicationRecord
    GOOGLE = 'google'
    DISCORD = 'discord'
    YANDEX = 'yandex'

    belongs_to :user

    enum :provider, { GOOGLE => 1, DISCORD => 2, YANDEX => 3 }

    scope :active, -> { where(active: true) }
  end
end

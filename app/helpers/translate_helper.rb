# frozen_string_literal: true

module TranslateHelper
  def translate(hash)
    return unless hash.is_a?(Hash)

    hash = hash.with_indifferent_access
    return hash[I18n.locale] if hash[I18n.locale].present?

    hash['en'] || hash[:en]
  end
end

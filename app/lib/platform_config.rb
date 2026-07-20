# frozen_string_literal: true

module PlatformConfig
  extend self

  def data(provider, version: '0.4.12')
    Rails.cache.fetch("#{provider}/#{version}", expires_in: 3.days) { load_data(provider) }
  end

  private

  # A provider config may declare `"base": "<other-provider>"` to inherit that
  # provider's config instead of copying it; the declaring provider's own keys
  # deep-merge on top (its values win, nested hashes combine key-by-key, arrays
  # replace wholesale). Chained bases resolve recursively. The merge runs inside
  # `data`'s cache block, so it is computed once per cache window -- a tlc.json
  # edit only surfaces after a version bump or cache clear (plan L871-873).
  def load_data(provider)
    config = read_config(provider)
    base = config['base']
    return config unless base

    load_data(base).deep_merge(config.except('base'))
  end

  def read_config(provider)
    JSON.parse(Rails.root.join("app/javascript/applications/CharKeeperApp/data/#{provider}.json").read)
  end
end

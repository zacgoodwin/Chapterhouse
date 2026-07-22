# frozen_string_literal: true

module PlatformConfig
  extend self

  CONFIG_DIR = Rails.root.join('app/javascript/applications/CharKeeperApp/data')
  # Content-addressed cache version. The merged config is a pure function of
  # these files, and production's redis store survives deploys, so a
  # hand-maintained number means a tlc.json change ships behind the stale key it
  # already warmed and serves the old config for the rest of the 3-day window.
  # Digesting the inputs makes every content change its own key. Computed once
  # per boot -- the files cannot change under a running process.
  CONFIG_VERSION =
    Digest::SHA256.hexdigest(Dir[CONFIG_DIR.join('*.json')].map { |file| File.read(file) }.join)[0, 12]

  def data(provider, version: CONFIG_VERSION)
    Rails.cache.fetch("#{provider}/#{version}", expires_in: 3.days) { load_data(provider) }
  end

  private

  # A provider config may declare `"base": "<other-provider>"` to inherit that
  # provider's config instead of copying it; the declaring provider's own keys
  # deep-merge on top (its values win, nested hashes combine key-by-key, arrays
  # replace wholesale). Chained bases resolve recursively. The merge runs inside
  # `data`'s cache block, so it is computed once per cache window -- a tlc.json
  # edit surfaces once the process restarts and CONFIG_VERSION re-digests
  # (plan L871-873).
  def load_data(provider)
    config = read_config(provider)
    base = config['base']
    return config unless base

    load_data(base).deep_merge(config.except('base'))
  end

  def read_config(provider)
    JSON.parse(CONFIG_DIR.join("#{provider}.json").read)
  end
end

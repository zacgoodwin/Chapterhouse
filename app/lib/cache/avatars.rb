# frozen_string_literal: true

module Cache
  class Avatars
    include Rails.application.routes.url_helpers

    CACHE_KEY = 'avatars/0.4.4'

    def fetch_list
      Rails.cache.fetch(CACHE_KEY) { load_initial_data }
    end

    def fetch_item(id:)
      fetch_list[id]
    end

    def push_item(item:)
      Rails.cache.write(
        CACHE_KEY,
        fetch_list.merge(item.record_id => rails_blob_url(item, host: host, protocol: protocol))
      )
    end

    def refresh_list
      Rails.cache.write(CACHE_KEY, load_initial_data)
    end

    private

    def load_initial_data
      ActiveStorage::Attachment.where(name: 'avatar', record_type: 'Character')
        .includes(:blob)
        .each_with_object({}) do |item, acc|
          acc[item.record_id] = rails_blob_url(item, host: host, protocol: protocol)
        end
    end

    def host
      return 'localhost:5000' if Rails.env.development?

      'charkeeper.org'
    end

    # dev serves plain HTTP; a hardcoded https would fail TLS on localhost
    def protocol
      Rails.env.development? ? 'http' : 'https'
    end
  end
end

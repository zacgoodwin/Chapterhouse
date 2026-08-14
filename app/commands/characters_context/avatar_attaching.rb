# frozen_string_literal: true

module CharactersContext
  # Avatar upload branch shared by the provider update commands: at most one of
  # avatar_file/avatar_url/file arrives (the contracts enforce it), and a failed
  # upload must never fail the update that carried it.
  module AvatarAttaching
    private

    def upload_avatar(input) # rubocop: disable Metrics/AbcSize
      return if input.slice(:avatar_file, :avatar_url, :file).keys.blank?

      attach_avatar_by_file.call({ character: input[:character], file: input[:avatar_file] }) if input[:avatar_file]
      attach_avatar_by_url.call({ character: input[:character], url: input[:avatar_url] }) if input[:avatar_url]
      return unless input[:file]

      input[:character].avatar.attach(input[:file])
      cache.push_item(item: input[:character].avatar)
    rescue StandardError => _e
    end
  end
end

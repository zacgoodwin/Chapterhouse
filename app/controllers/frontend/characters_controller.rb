# frozen_string_literal: true

module Frontend
  class CharactersController < Frontend::BaseController
    include SerializeResource

    DND_SERIALIZE_FIELDS = %i[id name level race subrace species legacy classes provider avatar].freeze

    before_action :find_character, only: %i[show destroy]
    before_action :set_locale, only: %i[show]

    def index
      render json: Panko::Response.new(
        characters: characters.flatten.sort_by { |item| item['name'] }
      ), status: :ok
    end

    def show
      serialize_resource(@character, serializer(@character.type), :character, { except: %i[avatar] })
    end

    def destroy
      @character.destroy
      only_head_response
    end

    private

    def characters
      current_user.characters.group_by(&:type).map do |character_type, characters|
        set_locale
        Panko::ArraySerializer.new(
          characters,
          each_serializer: serializer(character_type),
          only: DND_SERIALIZE_FIELDS,
          context: { simple: true }
        ).to_a
      end
    end

    def find_character
      @character = authorized_scope(Character.all).find(params.expect(:id))
    end

    def serializer(character_type)
      "#{character_type}Serializer".constantize
    end
  end
end

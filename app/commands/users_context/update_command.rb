# frozen_string_literal: true

module UsersContext
  class UpdateCommand < BaseCommand
    use_contract do
      config.messages.namespace = :user

      Locales = Dry::Types['strict.string'].enum('en')
      ColorSchemas = Dry::Types['strict.string'].enum(*User.color_schemas.keys)

      params do
        required(:user).filled(type?: ::User)
        optional(:locale).filled(Locales)
        optional(:username).filled(:string, max_size?: 50)
        optional(:color_schema).filled(ColorSchemas)
      end

      rule(:username) do
        next if value.blank?

        key.failure(:invalid) if !/[\w+\-\_]+/i.match?(value) || User.exists?(username: value)
      end
    end

    private

    def do_persist(input)
      input[:user].update!(input.except(:user))

      { result: input[:user] }
    end
  end
end

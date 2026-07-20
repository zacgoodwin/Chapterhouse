# frozen_string_literal: true

# app/views/layouts/adminbook.html.erb renders `stylesheet_link_tag 'tailwind'`,
# which needs app/assets/builds/tailwind.css on disk. That file is gitignored
# (it's a build artifact) -- tailwindcss-rails normally hooks its compile step
# into `rails db:test:prepare` / `rails test`, but this suite runs via
# `bundle exec rspec`, which never touches those Rake tasks. On a fresh
# checkout the asset is simply missing, and every adminbook request spec
# blows up with Sprockets::Rails::Helper::AssetNotFound.
#
# Build it once, automatically, before any spec runs so a fresh checkout is
# green with no manual pre-step. Skipped when the asset already exists (e.g.
# a second run in the same checkout), so this costs nothing after the first.
RSpec.configure do |config|
  config.before(:suite) do
    tailwind_css = Rails.root.join('app/assets/builds/tailwind.css')

    next if tailwind_css.exist? && !tailwind_css.empty?

    command = Tailwindcss::Commands.compile_command
    system(*command, exception: true)
  end
end

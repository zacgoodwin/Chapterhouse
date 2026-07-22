# frozen_string_literal: true

require 'open3'

# The SolidJS side has no test runner of its own, and this repo has no CI, so
# the only thing that reliably runs before a merge is `bundle exec rspec`.
# Hang node's built-in runner off it (same trick as spec/support/tailwind_asset.rb
# shelling out to the tailwind compiler) so the tlcConfig merge contract and the
# `=== 'dnd2024'` sweep are gated instead of remembered. The glob is passed
# through verbatim; node expands it itself.
describe 'spec/javascript (node --test suite)' do # rubocop: disable RSpec/DescribeClass
  it 'passes node --test' do
    output, status = Open3.capture2e('node', '--test', 'spec/javascript/*.test.js', chdir: Rails.root.to_s)

    expect(status).to be_success, output
  end
end

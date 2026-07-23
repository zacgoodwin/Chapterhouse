# frozen_string_literal: true

# The gem lives in the development+production Gemfile groups, so the test
# boot never loads it and the initializer no-ops behind defined?. Requiring
# it here defines the constant without running its railtie (boot is over),
# which is exactly enough to exercise the initializer's logic.
require 'rails_performance'

# rails_performance's middleware and monitor thread hard-require Redis on
# every request, so the initializer gates enablement: a production process
# without REDIS_URL (the dev Fly app) must disable it or every request 503s.
describe 'config/initializers/rails_performance' do # rubocop: disable RSpec/DescribeClass
  let(:initializer) { Rails.root.join('config/initializers/rails_performance.rb') }

  around do |example|
    original_enabled = RailsPerformance.enabled
    original_redis = ENV.fetch('REDIS_URL', nil)
    example.run
  ensure
    original_redis.nil? ? ENV.delete('REDIS_URL') : ENV['REDIS_URL'] = original_redis
    RailsPerformance.enabled = original_enabled
  end

  it 'disables the middleware in production without Redis (dev Fly instance)' do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
    ENV.delete('REDIS_URL')

    load initializer

    expect(RailsPerformance.enabled).to be false
  end

  it 'stays enabled in production when REDIS_URL is set (prod Fly instance)' do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
    ENV['REDIS_URL'] = 'redis://localhost:6379/9'

    load initializer

    expect(RailsPerformance.enabled).to be true
  end

  it 'stays enabled outside production regardless of Redis (local dev)' do
    ENV.delete('REDIS_URL')

    load initializer

    expect(RailsPerformance.enabled).to be true
  end
end

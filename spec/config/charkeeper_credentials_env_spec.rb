# frozen_string_literal: true

require 'rails_helper'

describe Charkeeper do
  around do |example|
    original = ENV.fetch('CREDENTIALS_ENV', nil)
    example.run
  ensure
    original.nil? ? ENV.delete('CREDENTIALS_ENV') : ENV['CREDENTIALS_ENV'] = original
  end

  it 'defaults to the Rails env' do
    ENV.delete('CREDENTIALS_ENV')
    expect(described_class.credentials_env).to eq(:test)
  end

  it 'is overridden by CREDENTIALS_ENV' do
    ENV['CREDENTIALS_ENV'] = 'development'
    expect(described_class.credentials_env).to eq(:development)
  end

  it 'ignores a blank CREDENTIALS_ENV' do
    ENV['CREDENTIALS_ENV'] = ''
    expect(described_class.credentials_env).to eq(:test)
  end

  it 'raises on an unknown section name instead of digging nil config' do
    ENV['CREDENTIALS_ENV'] = 'prod'
    expect { described_class.credentials_env }.to raise_error(ArgumentError, /unknown CREDENTIALS_ENV/)
  end

  it 'refuses the production section on the dev Fly app' do
    original_app = ENV.fetch('FLY_APP_NAME', nil)
    ENV['FLY_APP_NAME'] = 'chapterhouse-dev'
    ENV['CREDENTIALS_ENV'] = 'production'
    expect { described_class.credentials_env }.to raise_error(ArgumentError, /chapterhouse-dev/)
  ensure
    original_app.nil? ? ENV.delete('FLY_APP_NAME') : ENV['FLY_APP_NAME'] = original_app
  end
end

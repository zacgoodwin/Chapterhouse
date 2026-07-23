# frozen_string_literal: true

describe ImgproxyApi::Requests::ProcessImage do
  subject(:client) { Class.new { include ImgproxyApi::Requests::ProcessImage }.new }

  around do |example|
    original = ENV.fetch('CREDENTIALS_ENV', nil)
    example.run
  ensure
    original.nil? ? ENV.delete('CREDENTIALS_ENV') : ENV['CREDENTIALS_ENV'] = original
  end

  it 'digs imgproxy credentials from the section CREDENTIALS_ENV selects' do
    ENV['CREDENTIALS_ENV'] = 'development'
    allow(Rails.application.credentials).to receive(:dig).with(:development, :imgproxy).and_return(:dev_imgproxy)

    expect(client.send(:credentials)).to eq(:dev_imgproxy)
  end

  it 'falls back to the Rails env section without the override' do
    ENV.delete('CREDENTIALS_ENV')
    allow(Rails.application.credentials).to receive(:dig).with(:test, :imgproxy).and_return(:test_imgproxy)

    expect(client.send(:credentials)).to eq(:test_imgproxy)
  end
end

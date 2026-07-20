# frozen_string_literal: true

# Gates for the Supabase migration invariants. All checks are local and
# deterministic: they inspect config objects and repo files, never the
# network.
describe 'Supabase migration gates' do # rubocop: disable RSpec/DescribeClass
  describe 'database configuration' do
    %w[development test production].each do |env|
      it "#{env} has a single primary database" do
        configs = ActiveRecord::Base.configurations.configs_for(env_name: env, include_hidden: true)

        expect(configs.map(&:name)).to eq(['primary'])
      end
    end

    it 'test env stays on localhost so the truncating suite can never touch Supabase', :aggregate_failures do
      config = ActiveRecord::Base.configurations.configs_for(env_name: 'test').first.configuration_hash

      expect(config[:host]).to eq 'localhost'
      expect(config[:database]).to eq 'charkeeper_test'
    end

    %w[development production].each do |env|
      it "#{env} requires SSL" do
        config = ActiveRecord::Base.configurations.configs_for(env_name: env).first.configuration_hash

        expect(config[:sslmode]).to eq 'require'
      end
    end
  end

  describe 'schema hygiene' do
    # a dev-side db:migrate against Supabase would re-dump schema.rb with
    # catalog noise (extensions.*, pg_graphql, supabase_vault, ...) that
    # breaks localhost test schema loads
    it 'schema.rb declares only the app extensions' do
      extensions = Rails.root.join('db/schema.rb').read.scan(/enable_extension "([^"]+)"/).flatten

      expect(extensions - ['pg_catalog.plpgsql', 'pgcrypto', 'uuid-ossp']).to be_empty
    end

    it 'errors schema is gone' do
      expect(Rails.root.join('db/errors_schema.rb').exist?).to be false
    end
  end

  describe 'removed subsystems' do
    it 'solid_errors is gone', :aggregate_failures do
      expect(defined?(SolidErrors)).to be_nil
      expect(Rails.root.join('Gemfile').read).not_to include('solid_errors')
    end

    it 'authkeeper is gone', :aggregate_failures do
      expect(defined?(Authkeeper)).to be_nil
      expect(Rails.root.join('Gemfile').read).not_to include('authkeeper')
    end

    it 'no cable or solid_errors routes remain' do
      paths = Rails.application.routes.routes.map { |route| route.path.spec.to_s }

      expect(paths.none? { |path| path.start_with?('/cable', '/solid_errors') }).to be true
    end
  end

  describe 'storage wiring' do
    let(:storage_config) do
      YAML.load(ERB.new(Rails.root.join('config/storage.yml').read).result, aliases: true)
    end

    it 'defines the supabase S3 service', :aggregate_failures do
      expect(storage_config['supabase']['service']).to eq 'S3'
      expect(storage_config['supabase']['force_path_style']).to be true
    end

    it 'test env stores on disk' do
      expect(Rails.application.config.active_storage.service).to eq :test
    end
  end

  describe 'supabase config' do
    it 'test env uses a static JWK Set so no spec fetches JWKS' do
      expect(Rails.application.config.x.supabase.jwks).to be_present
    end
  end
end

# syntax=docker/dockerfile:1
# Production image for Fly.io. Build: fly deploy (remote builder; local Docker
# not required). The image carries no credentials: RAILS_MASTER_KEY and the
# Supabase settings arrive at runtime via fly secrets.
ARG RUBY_VERSION=3.4.1
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development test" \
    RAILS_LOG_TO_STDOUT=1 \
    PORT=3000

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libpq5 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config

# Node only exists in the build stage (esbuild + tailwind); 22.x honors the
# repo's .node-version pin and satisfies @supabase/supabase-js (needs >=22).
# yarn matches yarn.lock, which jsbundling-rails selects over package-lock.json.
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    npm install -g yarn

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .

RUN chmod +x bin/* && \
    bundle exec bootsnap precompile app/ lib/

# Keyless build: SECRET_KEY_BASE_DUMMY relaxes require_master_key
# (config/environments/production.rb) and database.yml resolves to nils.
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
    rm -rf node_modules

FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p log tmp public/assets app/assets/builds && \
    chown -R rails:rails log tmp public/assets app/assets/builds
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Default process; fly.toml [processes] overrides per group (web / worker).
EXPOSE 3000
CMD ["./bin/rails", "server"]

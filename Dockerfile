# Defines the Docker image build process for the Rails application.
#
# Builds a multi-stage production image with optimized dependency installation,
# asset precompilation, Bootsnap caching, and a non-root runtime user for
# improved security and reduced image size.
#
# @author Moisés Reis

ARG RUBY_VERSION=3.4.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install runtime system packages required by Rails and native gems.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libvips \
      postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Configure Bundler and memory allocator settings for production.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# ============================================================================
# BUILD STAGE
# ============================================================================

FROM base AS build

# Install compilation dependencies required for native extensions.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy dependency manifests and install Ruby gems.
COPY Gemfile Gemfile.lock vendor ./

RUN bundle install && \
    rm -rf \
      ~/.bundle/ \
      "${BUNDLE_PATH}"/ruby/*/cache \
      "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

# Copy application source code into the image.
COPY . .

# Precompile Bootsnap cache for application directories.
RUN bundle exec bootsnap precompile -j 1 app/ lib/

# Normalize executable scripts for Unix compatibility.
RUN chmod +x bin/* && \
    sed -i "s/\r$//g" bin/* && \
    sed -i 's/ruby\.exe$/ruby/' bin/*

# Precompile Rails assets for production deployment.
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ============================================================================
# RUNTIME STAGE
# ============================================================================

FROM base

# Create a non-root user for secure container execution.
RUN groupadd --system --gid 1000 rails && \
    useradd rails \
      --uid 1000 \
      --gid 1000 \
      --create-home \
      --shell /bin/bash

USER 1000:1000

# Copy bundled gems and application files from the build stage.
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

# Configure the application entrypoint.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80

# Start the Rails server through the Thruster process wrapper.
CMD ["./bin/thrust", "./bin/rails", "server"]

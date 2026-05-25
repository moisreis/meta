# syntax=docker/dockerfile:1

# ===============================================================
#                          DOCKERFILE
# ===============================================================
#
# Multi-stage production build for a Rails application with
# optimized runtime footprint, deterministic builds, and
# secure execution model.

ARG RUBY_VERSION=3.4.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# --- SYSTEM DEPENDENCIES --------------------------------------

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libvips \
      postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# --- ENVIRONMENT CONFIGURATION ---------------------------------

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# ===============================================================
#                      BUILD STAGE
# ===============================================================

FROM base AS build

# --- BUILD TOOLCHAIN ------------------------------------------

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# --- GEM INSTALLATION -----------------------------------------

COPY Gemfile Gemfile.lock vendor ./

RUN bundle install && \
    rm -rf \
      ~/.bundle/ \
      "${BUNDLE_PATH}"/ruby/*/cache \
      "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

# --- SOURCE LOADING -------------------------------------------

COPY . .

# --- BOOTSNAP PRECOMPILATION ----------------------------------

RUN bundle exec bootsnap precompile -j 1 app/ lib/

# --- SCRIPT NORMALIZATION -------------------------------------

RUN chmod +x bin/* && \
    sed -i "s/\r$//g" bin/* && \
    sed -i 's/ruby\.exe$/ruby/' bin/*

# --- ASSET PRECOMPILATION -------------------------------------

RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ===============================================================
#                    RUNTIME STAGE
# ===============================================================

FROM base

# --- USER SETUP -----------------------------------------------

RUN groupadd --system --gid 1000 rails && \
    useradd rails \
      --uid 1000 \
      --gid 1000 \
      --create-home \
      --shell /bin/bash

USER 1000:1000

# --- BUNDLE LOADING -------------------------------------------

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"

# --- RESOURCE LOADING -----------------------------------------

COPY --chown=rails:rails --from=build /rails /rails

# --- ENTRYPOINT -----------------------------------------------

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# --- NETWORK ---------------------------------------------------

EXPOSE 80

# --- DEFAULT COMMAND ------------------------------------------

CMD ["./bin/thrust", "./bin/rails", "server"]
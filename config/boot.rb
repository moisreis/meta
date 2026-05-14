# Bootstraps Bundler and initializes boot-time performance optimizations.
#
# This file configures the application Gemfile path, loads all Bundler-managed
# gem dependencies, and enables Bootsnap to cache expensive filesystem and
# load path operations during application startup.
#
# Environment Variables:
# - BUNDLE_GEMFILE: [String] Absolute path to the Gemfile used by Bundler.
#                                Defaults to ../Gemfile relative to this file.
#
# @author Moisés Reis

# ============================================================================
# BUNDLER SETUP
# ============================================================================

# Ensure Bundler uses the correct Gemfile path.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Load gems declared in the Gemfile.
require "bundler/setup"

# ============================================================================
# BOOT PERFORMANCE OPTIMIZATION
# ============================================================================

# Improve boot performance through filesystem and load path caching.
require "bootsnap/setup"

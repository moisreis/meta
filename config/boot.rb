# Bootstraps Bundler and initializes performance optimizations for the Rails application.
#
# This file sets up the Gemfile path, loads gem dependencies via Bundler,
# and enables Bootsnap to cache expensive operations during application boot.
#
# Environment Variables:
# - BUNDLE_GEMFILE: [String] Absolute path to the Gemfile used by Bundler.
#   Defaults to ../Gemfile relative to this file.
#
# TABLE OF CONTENTS:
#
# 1. Bundler Setup
# 2. Performance Optimization
#
# @author Moisés Reis

# =============================================================
#                     1. BUNDLER SETUP
# =============================================================

# Ensure Bundler uses the correct Gemfile.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Load gems specified in the Gemfile.
require "bundler/setup"

# =============================================================
#                2. PERFORMANCE OPTIMIZATION
# =============================================================

# Speed up boot time by caching expensive operations.
require "bootsnap/setup"

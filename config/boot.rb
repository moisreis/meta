# frozen_string_literal: true

# config/boot.rb
#
# Sets the Bundler environment and enables Bootsnap for boot acceleration.
#
# Runs before Rails is loaded to resolve the correct Gemfile and activate
# Bootsnap's caching for load path, require, and bytecode compilation.
# Does not configure application behaviour or initialize any framework components.
#
# @author  Moisés Reis

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup"
require "bootsnap/setup"
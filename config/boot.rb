# Sets the Bundler environment and loads bootsnap for
# application boot acceleration.
#
# This file runs before Rails is loaded to ensure the correct
# Gemfile is resolved and to enable bootsnap's caching for
# load path, require, and bytecode.
#
# This file does not configure application behaviour or
# initialize any framework components.
#
# @author Moisés Reis
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup"

require "bootsnap/setup"
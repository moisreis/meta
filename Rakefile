# frozen_string_literal: true

# Bootstraps the Rails application and loads all Rake tasks.
#
# This file initializes the Rails environment and exposes
# application-defined and framework-provided Rake tasks to the
# command-line interface.
#
# @author Moisés Reis

# =============================================================
#                        APPLICATION BOOT
# =============================================================

# Loads the Rails application definition and environment setup.
#
# @return [void]
require_relative "config/application"

# =============================================================
#                        TASK REGISTRATION
# =============================================================

# Loads all Rake tasks defined by Rails and the application.
#
# This makes tasks available via `bin/rake` or `rails` CLI.
#
# @return [void]
Rails.application.load_tasks
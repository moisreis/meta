# Configures and boots the Puma application server for the Rails application.
#
# This file defines thread counts, port bindings, and plugin configurations
# necessary for handling concurrent requests and optional background job execution.
#
# Environment Variables:
# - RAILS_MAX_THREADS:   [Integer] Maximum number of threads per worker (default: 3).
# - PORT:                [Integer] Port the server binds to (default: 3000).
# - SOLID_QUEUE_IN_PUMA: [Boolean] Enables Solid Queue integration within Puma.
# - PIDFILE:             [String] File path for storing the server process ID.
#
# TABLE OF CONTENTS:
#
# 1. Thread and Connection Settings
# 2. Server Plugins and Process ID
#
# @author Moisés Reis

# =============================================================
#              1. THREAD AND CONNECTION SETTINGS
# =============================================================

threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

port ENV.fetch("PORT", 3000)

# =============================================================
#                2. SERVER PLUGINS AND PROCESS ID
# =============================================================

plugin :tmp_restart

plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

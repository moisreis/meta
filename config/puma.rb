# Configures and boots the Puma application server for the Rails application.
#
# This file defines thread pool settings, port bindings, process management,
# and optional plugin integrations required for serving concurrent HTTP
# requests in the application runtime environment.
#
# Environment Variables:
# - RAILS_MAX_THREADS:   [Integer] Maximum number of threads per Puma worker
#                                   (default: 3).
# - PORT:                [Integer] TCP port bound by the server
#                                   (default: 3000).
# - SOLID_QUEUE_IN_PUMA: [Boolean] Enables Solid Queue integration within Puma.
# - PIDFILE:             [String] Absolute or relative path to the server PID file.
#
# @author Moisés Reis

# ============================================================================
# THREAD POOL & NETWORK CONFIGURATION
# ============================================================================

threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)

threads threads_count, threads_count

port ENV.fetch("PORT", 3000)

# ============================================================================
# SERVER PLUGINS & PROCESS MANAGEMENT
# ============================================================================

plugin :tmp_restart

plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

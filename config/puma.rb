# frozen_string_literal: true

# Configures the Puma application server runtime behavior.
#
# This configuration defines threading, network binding,
# restart behavior, optional queue integration, and process
# identification for external supervision tools.
#
# @author Moisés Reis

# =============================================================
#                      THREAD CONFIGURATION
# =============================================================

# Number of threads used per Puma worker.
#
# The value is sourced from RAILS_MAX_THREADS, defaulting to 3.
#
# @return [Integer]
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)

# Sets both minimum and maximum thread pool size.
#
# A fixed thread pool is used to ensure predictable concurrency behavior.
#
# @param threads_count [Integer]
#   Number of threads allocated per worker process.
#
# @return [void]
threads threads_count, threads_count

# =============================================================
#                        SERVER BINDING
# =============================================================

# TCP port used by the Puma HTTP server.
#
# Falls back to port 3000 when ENV["PORT"] is not defined.
#
# @return [void]
port ENV.fetch("PORT", 3000)

# =============================================================
#                          PLUGINS
# =============================================================

# Enables automatic restart support based on tmp file changes.
#
# @return [void]
plugin :tmp_restart

# Enables Solid Queue integration when explicitly enabled.
#
# @return [void]
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# =============================================================
#                      PROCESS MANAGEMENT
# =============================================================

# Writes the Puma process ID to a file for external supervision.
#
# Typically used by systemd, Docker, or deployment tooling.
#
# @return [void]
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
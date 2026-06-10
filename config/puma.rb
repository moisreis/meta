# frozen_string_literal: true

# config/puma.rb
#
# Configures the Puma application server.
#
# Defines threading, network binding, plugin integration,
# and process management settings used during application
# execution.
#
# @author  Moisés Reis

# == Thread Configuration ====================================================

threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)

threads threads_count, threads_count


# == Server Binding ==========================================================

port ENV.fetch("PORT", 3000)


# == Plugins =================================================================

plugin :tmp_restart

plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]


# == Process Management ======================================================

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
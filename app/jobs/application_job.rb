# frozen_string_literal: true

# Base class for all background jobs in the application.
#
# This class provides a centralized location for shared configuration, retries,
# error handling, and cross-cutting concerns across all asynchronous tasks.
#
# @author Moisés Reis

class ApplicationJob < ActiveJob::Base
end
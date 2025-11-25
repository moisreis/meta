# === application_job
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This is the base class for all background jobs in the application. It provides a common configuration
#              and environment for tasks that run outside the normal web request-response cycle.
#              The explanations are in the present simple tense.
# @category *Job*
#
# Usage:: - *[What]* This code block defines the foundational settings for all long-running, non-urgent tasks in the application.
#         - *[How]* It inherits from **ActiveJob::Base** and is automatically configured to use a specific queuing system
#           (like Sidekiq or Delayed Job) to process tasks asynchronously.
#         - *[Why]* It ensures that slow operations (like sending emails, generating large reports, or importing data)
#           do not slow down the website, leading to a faster and smoother experience for the user.
#
class ApplicationJob < ActiveJob::Base
end
# === application_mailer
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This is the base class for all mailer components in the application. It establishes default settings
#              like the sender address and the standard template layout for all outgoing emails.
#              The explanations are in the present simple tense.
# @category *Mailer*
#
# Usage:: - *[What]* This code block defines the foundational settings that every email sent by the application uses automatically.
#         - *[How]* It inherits from **ActionMailer::Base** and specifies the default sender email and the base design (layout) for the email content.
#         - *[Why]* It ensures all communications (like password resets, notifications, or reports)
#           have a consistent sending address and appearance without needing to set them in every individual mailer file.
#
class ApplicationMailer < ActionMailer::Base

  # Explanation:: This sets the default email address that all emails originating from the application
  #               use as their sender. Individual mailers can override this if necessary.
  default from: "from@example.com"

  # Explanation:: This specifies the standard design template (`mailer.html.erb` or `mailer.text.erb`)
  #               that wraps the content of all emails sent by the application.
  layout "mailer"
end
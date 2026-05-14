# frozen_string_literal: true

# Base mailer class for the application.
#
# Provides shared configuration for all outbound emails, including default
# sender address and layout selection.
#
# @author Moisés Reis

class ApplicationMailer < ActionMailer::Base
  default from: "contato@meta-investimentos.app.br"
  layout "mailer"
end

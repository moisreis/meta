# frozen_string_literal: true

# config/initializers/filter_parameter_logging.rb
#
# Configures parameter filtering for Rails logs.
#
# Sensitive request parameters such as credentials, tokens,
# and personal identifiers are filtered to prevent exposure
# in log output.
#
# @author  Moisés Reis

Rails.application.config.filter_parameters += %i[
  passw
  email
  secret
  token
  _key
  crypt
  salt
  certificate
  otp
  ssn
  cvv
  cvc
]
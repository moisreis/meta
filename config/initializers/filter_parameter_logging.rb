# Registers parameter keys to be filtered from Rails logs.
#
# Prevents sensitive data — passwords, tokens, secrets, and
# personal identifiers — from appearing in log output.
#
# This file does not configure encryption, authentication,
# or network-level request filtering.
#
# @author Moisés Reis
Rails.application.config.filter_parameters += [
  :passw,
  :email,
  :secret,
  :token,
  :_key,
  :crypt,
  :salt,
  :certificate,
  :otp,
  :ssn,
  :cvv,
  :cvc
]

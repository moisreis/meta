# Configures parameter filtering to prevent sensitive data from being logged.
#
# This file defines a list of parameter keys that should be masked in logs,
# reducing the risk of exposing confidential information such as credentials,
# tokens, and personal data.
#
# @author Moisés Reis

# =============================================================
# SENSITIVE PARAMETER FILTERING
# =============================================================

# Configure parameters to be partially matched and filtered from logs.
# Supports partial matching (e.g., :passw matches :password).
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

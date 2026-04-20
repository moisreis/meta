# Boots and initializes the Rails application environment.
#
# This file loads the application configuration and triggers the
# initialization process required to prepare the framework for execution.
#
# TABLE OF CONTENTS:
#
# 1. Application Boot & Initialization
#
# @author Moisés Reis

# =============================================================
#            1. APPLICATION BOOT & INITIALIZATION
# =============================================================

# Load the Rails application configuration.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

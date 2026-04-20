# Configures asset pipeline versioning and load paths for the Rails application.
#
# This file defines the asset version used for cache invalidation and allows
# extension of asset lookup paths for additional resources.
#
# TABLE OF CONTENTS:
#
# 1. Asset Versioning
# 2. Asset Load Paths
#
# @author Moisés Reis

# =============================================================
#                    1. ASSET VERSIONING
# =============================================================

# Version of assets used for cache invalidation.
# Incrementing this value forces clients to reload all assets.
Rails.application.config.assets.version = "1.0"

# =============================================================
#                    2. ASSET LOAD PATHS
# =============================================================

# Add additional asset directories to the pipeline.
# Rails.application.config.assets.paths << Images.images_path

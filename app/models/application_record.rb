# Base class for all application models, providing core database interaction.
#
# This class serves as the fundamental abstract parent for all database-backed
# models, ensuring consistency and DRY (Don't Repeat Yourself) configurations
# across the application's data layer.
#
# @author Moisés Reis
# @abstract Subclass this to create a new database model.
class ApplicationRecord < ActiveRecord::Base

  # Declares this as an abstract base class for the entire application,
  # preventing it from being instantiated or mapped to a specific table.
  primary_abstract_class
end

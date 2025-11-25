# === application_record
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This class serves as the fundamental base from which all application
#              models, like **User**, **Product**, and **Order**, inherit their
#              core database interaction functionality and methods.
# @category *Model*
#
# Usage:: - *[What]* This is the parent class for all models in the application. It
#           provides a single place to configure settings and behaviors that apply
#           to every database-backed object.
#         - *[How]* It inherits from **ActiveRecord::Base** and then uses the
#           `primary_abstract_class` method to establish itself as the central
#           base class for your application's data layer.
#         - *[Why]* The application needs this class to ensure consistency and
#           adherence to the database schema and conventions across all models,
#           making the code DRY (Don't Repeat Yourself).
#
class ApplicationRecord < ActiveRecord::Base

  # Explanation:: This declares **ApplicationRecord** as an abstract class that
  #               should be used as the parent for all other models. It automatically
  #               sets the `table_name` to `nil`, preventing direct queries.
  primary_abstract_class
end
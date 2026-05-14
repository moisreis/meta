# Resolves the reference date for the portfolio analytics dashboard.
#
# Accepts a raw date string parameter and returns the corresponding
# {Date}, falling back to the current date when the parameter is
# absent or unparseable.
#
# @example Valid parameter
#   Portfolios::ReferenceDateResolver.call("2025-03-31")
#   #=> #<Date: 2025-03-31>
#
# @example Absent parameter
#   Portfolios::ReferenceDateResolver.call(nil)
#   #=> #<Date: 2025-05-11>  (today)
#
# @example Invalid parameter
#   Portfolios::ReferenceDateResolver.call("not-a-date")
#   #=> #<Date: 2025-05-11>  (today)
module Portfolios
  class ReferenceDateResolver

    # @param date_param [String, nil] Raw date string from request params.
    # @return [Date] Resolved dashboard reference date.
    def self.call(date_param)
      return Date.current unless date_param.present?

      Date.parse(date_param)
    rescue ArgumentError
      Date.current
    end

  end
end

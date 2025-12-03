# === performance_histories_helper
#
# @author Moisés Reis
# @added 12/3/2025
# @package *Meta*
# @description This helper module provides view-level support methods for
#              handling performance history data. It centralizes small
#              formatting and presentation routines so that related views
#              stay clean and expressive. If referencing other structures
#              in the app, such as **PerformanceHistory** or
#              **PerformanceHistoriesController**, they appear in bold.
# @category *Model*
#
# Usage:: - *[What]* This code block defines a dedicated helper namespace that
#           groups view-focused utilities for performance history presentation.
#         - *[How]* It does this by providing a module where helper methods can
#           be added and automatically included in the corresponding
#           views, allowing formatting logic to stay out of the ERB templates.
#         - *[Why]* It needs to be in the app so that common formatting,
#           transformation, or small calculation routines related to
#           performance histories remain DRY, centralized, and easy to
#           test, instead of being duplicated across multiple views.
#
module PerformanceHistoriesHelper
end

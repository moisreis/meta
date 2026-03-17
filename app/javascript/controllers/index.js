// =============================================================
// Controller Registration
// =============================================================

// This file serves as the central registry for the application's
// Stimulus controllers, connecting them to the main application
// instance so they can be activated within the HTML views.

// This line imports the pre-configured Stimulus application
// instance from the local application definition file.
import {application} from "controllers/application"

// This statement registers the currency masking logic.
// It allows the application to format monetary inputs
// automatically as the user types in specific form fields.
import CurrencyMaskController from "controllers/currency_mask_controller"

application.register("currency-mask", CurrencyMaskController)

// This statement registers the CNPJ masking logic.
// It formats the Brazilian company registration number
// automatically as the user types in specific form fields.
import CnpjMaskController from "controllers/cnpj_mask_controller"

application.register("cnpj-mask", CnpjMaskController)

// This statement registers the bank account masking logic.
// It formats account numbers with the check digit separator
// automatically as the user types in specific form fields.
import BankAccountMaskController from "controllers/bank_account_mask_controller"

application.register("bank-account-mask", BankAccountMaskController)

// This statement registers the calculation progress tracker.
// It manages the real-time feedback and progress bar display
// during long-running performance calculation tasks.
import CalculationProgressController from "controllers/calculation_progress_controller"

application.register("calculation-progress", CalculationProgressController)

// This statement registers the enhanced selection logic.
// It replaces standard dropdown menus with searchable,
// stylized components to improve the user selection process.
import TomSelectController from "controllers/tom_select_controller"

application.register("tom-select", TomSelectController)

// This statement registers the calendar interface logic.
// It attaches a date picker to input fields, ensuring
// that dates are selected via a localized graphical menu.
import DatepickerController from "controllers/datepicker_controller"

application.register("datepicker", DatepickerController)

// This statement registers the tooltip and popover logic.
// It enables the display of contextual information or
// interactive menus when hovering over or clicking elements.
import TippyController from "controllers/tippy_controller"

application.register("tippy", TippyController)

// This statement registers the reference date synchronization logic.
// It synchronizes the selected date across the three portfolio action
// forms (view period, calculate performance, generate report) before
// each respective form is submitted.
import ReferenceDateController from "controllers/reference_date_controller"

application.register("reference-date", ReferenceDateController)

// This statement registers the toast notification logic.
// It reads flash messages passed from Rails and displays
// them as animated, auto-dismissing overlay notifications.
import ToastController from "controllers/toast_controller"

application.register("toast", ToastController)
# === errors_controller.rb
#
# @author Moisés Reis
# @added 02/11/2026
# @package *Meta*
# @description This controller manages how the system displays technical failures
#              or non-existent pages, transforming complex errors into friendly
#              messages for the user.
# @category *Controller*
#
# Usage:: - *[What]* A central hub for error messages that captures system failures.
#         - *[How]* It identifies the error type through **ActionDispatch** and
#           selects the appropriate message and view.
#         - *[Why]* It is essential for maintaining the app's visual identity
#           even when something goes wrong.
#
# Attributes:: - *[@status_code]* Integer - the numeric code identifying the type of error.
#              - *[@label]* String - a short label used to highlight the error code on screen.
#              - *[@title]* String - the main title explaining the error simply.
#              - *[@description]* String - supporting text that guides the user on what happened.
#
class ErrorsController < ApplicationController

  # This sets the controller to use a simplified and focused visual
  # design, separate from the rest of the main application.
  layout "error"

  # == show
  #
  # @author Moisés Reis
  # @category *Action*
  #
  # This action prepares and displays the error page corresponding to the
  # problem encountered. It retrieves text info based on the response code.
  #
  # Attributes:: - *@wrapper* - object containing technical details of the failure.
  #
  def show
    wrapper = exception_wrapper

    # Determines the final numeric error code after analyzing the failure.
    @status_code = normalize_status(wrapper)

    # Fetches user-friendly text configurations for this specific code.
    error_config = error_messages.fetch(@status_code, error_messages[404])

    @label = error_config[:label]
    @title = error_config[:title]
    @description = error_config[:description]

    # Selects the correct visual file and sends the response with the error code.
    render view_for_code(@status_code), status: @status_code
  end

  private

  # == exception_wrapper
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # This extracts the details of the failure that occurred within the Rails system.
  # It ensures that even routing errors are handled correctly.
  #
  def exception_wrapper

    # Attempts to retrieve the error captured by the Rails routing system
    # to understand what caused the request failure.
    exception = request.env["action_dispatch.exception"]

    ActionDispatch::ExceptionWrapper.new(
      request.env,
      exception || ActionController::RoutingError.new(request.path)
    )
  end

  # == normalize_status
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # This ensures that "page not found" errors always receive the 404 code,
  # avoiding confusion between internal actions and mistyped addresses.
  #
  def normalize_status(wrapper)
    case wrapper.exception
    when AbstractController::ActionNotFound
      404
    else
      wrapper.status_code
    end
  end

  # == view_for_code
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # This decides which view file should be loaded, returning the default
  # "Not Found" page if the error code is unknown.
  #
  def view_for_code(code)
    supported_error_codes.fetch(code, "404")
  end

  # == supported_error_codes
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # This lists the error codes that have their own specific visual
  # page within the system's view folder.
  #
  def supported_error_codes
    { 403 => "403", 404 => "404", 500 => "500" }
  end

  # == error_messages
  #
  # @author Moisés Reis
  # @category *Method*
  #
  # This stores the English text that explains each error didactically,
  # avoiding scary technical jargon for the end user.
  #
  def error_messages
    {
      403 => { label: "403", title: "Acesso Negado", description: "Você não tem permissão para acessar este recurso." },
      404 => { label: "404", title: "Página Não Encontrada", description: "A ação ou página solicitada não existe." },
      500 => { label: "500", title: "Erro Interno do Servidor", description: "Ocorreu um erro inesperado. Por favor, tente novamente mais tarde." }
    }
  end
end
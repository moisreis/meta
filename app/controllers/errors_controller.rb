# === errors_controller.rb
#
# @author Moisés Reis
# @added 02/11/2026
# @package *Meta*
# @description Este controlador gerencia como o sistema exibe falhas técnicas ou páginas
#              inexistentes, transformando erros complexos em mensagens amigáveis.
# @category *Controller*
#
# Usage:: - *[What]* Um centralizador de mensagens de erro que captura falhas do sistema.
#         - *[How]* Ele identifica o tipo de erro através do **ActionDispatch** e escolhe a mensagem certa.
#         - *[Why]* É essencial para manter a identidade visual do app mesmo quando algo dá errado.
#
# Attributes:: - *[@status_code]* Integer - o código numérico que identifica o tipo de erro ocorrido.
#              - *[@label]* String - uma etiqueta curta usada para destacar o código do erro na tela.
#              - *[@title]* String - o título principal que explica o erro de forma simples.
#              - *[@description]* String - um texto de apoio que orienta o usuário sobre o que aconteceu.
#
class ErrorsController < ApplicationController
  # Explanation:: Define que este controlador usará um visual simplificado e focado,
  #               separado do restante da aplicação principal.
  layout "error"

  # == show
  #
  # @author Moisés Reis
  # @category *Action* #
  # Category:: Prepara e exibe a página de erro correspondente ao problema encontrado.
  #            Busca as informações de texto baseadas no código de resposta.
  #
  # Attributes:: - *@wrapper* - objeto que contém os detalhes técnicos da falha ocorrida.
  #
  def show
    wrapper = exception_wrapper
    @status_code = normalize_status(wrapper)

    error_config = error_messages.fetch(@status_code, error_messages[404])

    @label       = error_config[:label]
    @title       = error_config[:title]
    @description = error_config[:description]

    render view_for_code(@status_code), status: @status_code
  end

  private

  # == exception_wrapper
  #
  # @author Moisés Reis
  # @category *Method* #
  # Category:: Extrai os detalhes da falha que aconteceu dentro do sistema Rails.
  #            Garante que até erros de rota sejam tratados corretamente.
  #
  def exception_wrapper
    # Explanation:: Tenta recuperar o erro capturado pelo sistema de rotas do Rails
    #               para entender o que causou a falha na requisição.
    exception = request.env["action_dispatch.exception"]

    ActionDispatch::ExceptionWrapper.new(
      request.env,
      exception || ActionController::RoutingError.new(request.path)
    )
  end

  def normalize_status(wrapper)
    case wrapper.exception
    when AbstractController::ActionNotFound
      404
    else
      wrapper.status_code
    end
  end

  def view_for_code(code)
    supported_error_codes.fetch(code, "404")
  end

  def supported_error_codes
    { 403 => "403", 404 => "404", 500 => "500" }
  end

  def error_messages
    {
      403 => { label: "403", title: "Acesso negado", description: "Você não tem permissão para acessar este recurso." },
      404 => { label: "404", title: "Página não encontrada", description: "A ação ou página solicitada não existe." },
      500 => { label: "500", title: "Erro interno do servidor", description: "Ocorreu um erro inesperado. Tente novamente mais tarde." }
    }
  end
end
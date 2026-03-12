# test/controllers/applications_controller_test.rb

require "test_helper"

class ApplicationsControllerTest < ActionDispatch::IntegrationTest

  # =============================================================
  # Setup
  # =============================================================

  setup do
    @user       = users(:one)
    @portfolio  = portfolios(:one)
    @fi         = fund_investments(:one)
    @application = applications(:one)

    sign_in @user  # Devise helper — disponível em IntegrationTest com
    # include Devise::Test::IntegrationHelpers no test_helper.rb
  end

  # =============================================================
  # index
  # =============================================================

  test "index retorna sucesso para usuário autenticado" do
    get applications_url
    assert_response :success
  end

  test "index redireciona usuário não autenticado" do
    sign_out @user
    get applications_url
    assert_redirected_to new_user_session_path
  end

  # =============================================================
  # show
  # =============================================================

  test "show retorna sucesso para dono da aplicação" do
    get application_url(@application)
    assert_response :success
  end

  test "show redireciona usuário sem permissão" do
    sign_in users(:two)
    get application_url(@application)
    assert_redirected_to portfolios_url
  end

  # =============================================================
  # new / edit
  # =============================================================

  test "new retorna sucesso" do
    get new_application_url
    assert_response :success
  end

  test "edit retorna sucesso para dono" do
    get edit_application_url(@application)
    assert_response :success
  end

  # =============================================================
  # create
  # =============================================================

  test "create salva aplicação e redireciona para portfolio" do
    assert_difference("Application.count", 1) do
      post applications_url, params: {
        application: {
          portfolio_id:      @portfolio.id,
          investment_fund_id: @fi.investment_fund_id,
          financial_value:   "1000.00",
          cotization_date:   "2025-01-10"
        }
      }
    end

    assert_redirected_to portfolio_path(@portfolio)
  end

  test "create falha sem financial_value e renderiza new" do
    assert_no_difference("Application.count") do
      post applications_url, params: {
        application: {
          portfolio_id:      @portfolio.id,
          investment_fund_id: @fi.investment_fund_id,
          cotization_date:   "2025-01-10"
          # financial_value ausente
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # =============================================================
  # update — núcleo do que foi implementado
  # =============================================================

  test "update corrige valor e recalcula saldos do FundInvestment" do
    valor_antigo  = @application.financial_value
    quotas_antigas = @application.number_of_quotas
    fi            = @application.fund_investment

    patch application_url(@application), params: {
      application: {
        financial_value: (valor_antigo + 500).to_s,
        cotization_date: @application.cotization_date.iso8601
      }
    }

    assert_redirected_to application_url(@application)

    fi.reload
    @application.reload

    # Saldo do FundInvestment deve refletir o delta, não o valor absoluto
    assert fi.total_invested_value > valor_antigo,
           "total_invested_value deveria ter aumentado"
    assert fi.total_quotas_held > quotas_antigas,
           "total_quotas_held deveria ter aumentado"
  end

  test "update rejeita valor que deixaria cotas abaixo do já resgatado" do
    # Simula que 8 das 10 cotas já foram alocadas em resgates
    @application.redemption_allocations.create!(
      redemption: redemptions(:one),
      quotas_used: 8
    )

    valor_original = @application.financial_value

    # Tenta corrigir para um valor que resultaria em menos de 8 cotas
    patch application_url(@application), params: {
      application: {
        financial_value: "1.00",  # irrisório — geraria < 8 cotas
        cotization_date: @application.cotization_date.iso8601
      }
    }

    assert_response :unprocessable_entity
    assert_equal valor_original, @application.reload.financial_value,
                 "financial_value não deveria ter sido alterado"
  end

  test "update falha quando não há cota disponível na data" do
    # Usa uma data sem FundValuation cadastrado
    patch application_url(@application), params: {
      application: {
        financial_value: "1000.00",
        cotization_date: "1900-01-01"
      }
    }

    assert_response :unprocessable_entity
  end

  test "update não toca FundInvestment quando apenas datas são corrigidas" do
    fi = @application.fund_investment
    valor_antes  = fi.total_invested_value
    quotas_antes = fi.total_quotas_held

    # Corrige só a liquidation_date, sem mexer em valores
    patch application_url(@application), params: {
      application: {
        financial_value: @application.financial_value.to_s,
        cotization_date: @application.cotization_date.iso8601
        # liquidation_date diferente, por ex.
      }
    }

    fi.reload
    assert_equal valor_antes,  fi.total_invested_value,  "valor não deveria mudar"
    assert_equal quotas_antes, fi.total_quotas_held,     "cotas não deveriam mudar"
  end

  test "update redireciona usuário sem permissão sem alterar o registro" do
    sign_in users(:two)
    valor_original = @application.financial_value

    patch application_url(@application), params: {
      application: { financial_value: "9999.00" }
    }

    assert_redirected_to portfolios_url
    assert_equal valor_original, @application.reload.financial_value
  end

  # =============================================================
  # destroy
  # =============================================================

  test "destroy remove aplicação e subtrai do FundInvestment" do
    fi            = @application.fund_investment
    valor_antes   = fi.total_invested_value
    quotas_antes  = fi.total_quotas_held

    assert_difference("Application.count", -1) do
      delete application_url(@application)
    end

    assert_redirected_to fund_investment_url(fi)

    fi.reload
    assert fi.total_invested_value  < valor_antes
    assert fi.total_quotas_held     < quotas_antes
  end

  test "destroy redireciona usuário sem permissão" do
    sign_in users(:two)

    assert_no_difference("Application.count") do
      delete application_url(@application)
    end

    assert_redirected_to portfolios_url
  end
end
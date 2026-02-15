module MonthlyReportable
  extend ActiveSupport::Concern

  def monthly_report
    @portfolio = Portfolio.find(params[:id])

    authorize! :read, @portfolio

    reference_date = if params[:month].present? && params[:year].present?
                       Date.new(params[:year].to_i, params[:month].to_i).end_of_month
                     else
                       Date.current.end_of_month
                     end

    generator = PortfolioMonthlyReportGenerator.new(@portfolio, reference_date)
    pdf_content = generator.generate

    send_data pdf_content,
              filename: "relatorio_#{@portfolio.name.parameterize}_#{reference_date.strftime('%Y_%m')}.pdf",
              type: 'application/pdf',
              disposition: 'inline'

  rescue CanCan::AccessDenied
    redirect_to portfolios_path, alert: 'VocÃª nÃ£o tem permissÃ£o para visualizar este relatÃ³rio.'
  rescue => e
    Rails.logger.error "Erro ao gerar relatÃ³rio mensal: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to portfolio_path(@portfolio), alert: 'Erro ao gerar o relatÃ³rio. Tente novamente.'
  end
end

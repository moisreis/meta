# lib/tasks/performance.rake

namespace :performance do
  desc "Calcula performance de todos os fundos para uma data específica"
  task calculate: :environment do
    target_date = ENV['DATE'] ? Date.parse(ENV['DATE']) : Date.yesterday

    puts "🚀 Iniciando cálculo de performance para #{target_date}..."
    result = PerformanceCalculationJob.perform_now(target_date: target_date)

    puts "✅ Concluído!"
    puts "   Processados: #{result[:processed]}"
    puts "   Criados: #{result[:created]}"
    puts "   Erros: #{result[:errors]}"
  end

  desc "Calcula performance para o mês inteiro"
  task calculate_month: :environment do
    year = ENV['YEAR']&.to_i || Date.current.year
    month = ENV['MONTH']&.to_i || Date.current.month

    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    puts "🚀 Calculando performance para #{start_date.strftime('%B/%Y')}..."

    (start_date..end_date).each do |date|
      next if date.sunday? || date.saturday? # Pula finais de semana

      puts "📅 Processando #{date}..."
      PerformanceCalculationJob.perform_now(target_date: date)
    end

    puts "✅ Mês completo processado!"
  end
end
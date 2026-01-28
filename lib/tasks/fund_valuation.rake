# lib/tasks/fund_valuation.rake

namespace :fund_valuation do
  desc "Importa cotas do CVM dos últimos meses"
  task import: :environment do
    # Explanation:: Permite especificar quantos meses buscar via variável de ambiente
    #               Padrão: 2 meses (mês atual + mês anterior)
    months_back = ENV['MONTHS']&.to_i || 2

    puts "🚀 Iniciando importação de cotas do CVM..."
    puts "📅 Buscando últimos #{months_back} meses"
    puts ""

    result = FundValuationImportJob.perform_now(months_back: months_back)

    puts ""
    puts "✅ Importação concluída!"
    puts "   Arquivos processados: #{result[:files_processed]}"
    puts "   Registros importados: #{result[:records_imported]}"
    puts "   Registros ignorados: #{result[:records_skipped]}"
    puts "   Duração: #{result[:duration_seconds]} segundos"
  end

  desc "Importa cotas de uma data específica"
  task :import_date, [:date] => :environment do |t, args|
    target_date = args[:date] ? Date.parse(args[:date]) : Date.current
    months_back = ENV['MONTHS']&.to_i || 2

    puts "🚀 Iniciando importação de cotas do CVM..."
    puts "📅 Data alvo: #{target_date.strftime('%d/%m/%Y')}"
    puts "📅 Buscando #{months_back} meses para trás"
    puts ""

    result = FundValuationImportJob.perform_now(
      start_date: target_date,
      months_back: months_back
    )

    puts ""
    puts "✅ Importação concluída!"
    puts "   Arquivos processados: #{result[:files_processed]}"
    puts "   Registros importados: #{result[:records_imported]}"
  end

  desc "Importa histórico completo (12 meses)"
  task import_full: :environment do
    puts "🚀 Iniciando importação completa de 12 meses..."
    puts "⚠️  Isso pode demorar alguns minutos..."
    puts ""

    result = FundValuationImportJob.perform_now(months_back: 12)

    puts ""
    puts "✅ Importação concluída!"
    puts "   Arquivos processados: #{result[:files_processed]}"
    puts "   Registros importados: #{result[:records_imported]}"
    puts "   Duração: #{result[:duration_seconds]} segundos"
  end

  desc "Importa apenas o mês de dezembro/2025 (para teste Jacoprev)"
  task import_december: :environment do
    puts "🚀 Importando cotas de dezembro/2025..."
    puts ""

    result = FundValuationImportJob.perform_now(
      start_date: Date.new(2025, 12, 31),
      months_back: 1  # Apenas dezembro
    )

    puts ""
    puts "✅ Importação concluída!"
    puts "   Arquivos processados: #{result[:files_processed]}"
    puts "   Registros importados: #{result[:records_imported]}"
  end
end
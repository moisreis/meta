# === add_initial_balance_to_performance_histories
#
# @author Moisés Reis
# @created 02/02/2026
# @package Migrations
# @description Adiciona coluna initial_balance para armazenar o saldo inicial
#              do período e corrigir o cálculo de rentabilidade
#
class AddInitialBalanceToPerformanceHistories < ActiveRecord::Migration[8.1]
  def change
    add_column :performance_histories, :initial_balance, :decimal, precision: 15, scale: 2

    # Adiciona índice para melhorar performance em queries
    add_index :performance_histories, :initial_balance
  end
end
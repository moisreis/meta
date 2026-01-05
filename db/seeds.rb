# frozen_string_literal: true

# Seed file for Redemptions
# This creates realistic redemption records based on existing fund investments

puts "Starting Redemptions seed..."

# Helper method to generate realistic redemption data
def generate_redemption(fund_investment, index, base_date)
  # Get the total quotas available
  total_quotas = fund_investment.total_quotas_held.to_f

  # Determine redemption type (weighted distribution)
  type_rand = rand(100)
  redemption_type = case type_rand
                    when 0..65 then "partial"      # 65% partial
                    when 66..80 then "total"       # 15% total
                    when 81..90 then "scheduled"   # 10% scheduled
                    else "emergency"                # 10% emergency
                    end

  # Calculate redeemed quotas based on type
  redeemed_quotas = case redemption_type
                    when "total"
                      total_quotas * rand(0.95..1.0) # Total: 95-100% of holdings
                    when "partial"
                      total_quotas * rand(0.05..0.45) # Partial: 5-45% of holdings
                    when "emergency"
                      total_quotas * rand(0.10..0.30) # Emergency: 10-30% of holdings
                    when "scheduled"
                      total_quotas * rand(0.15..0.50) # Scheduled: 15-50% of holdings
                    end

  # Generate quota value at redemption (with some market variation)
  avg_quota_value = (fund_investment.total_invested_value.to_f / total_quotas)
  market_variation = rand(0.85..1.15) # ±15% market variation
  quota_value = avg_quota_value * market_variation

  # Calculate liquid value
  redeemed_liquid_value = (redeemed_quotas * quota_value).round(2)

  # Calculate yield (difference from original investment value per quota)
  original_value_per_quota = avg_quota_value
  yield_per_quota = quota_value - original_value_per_quota
  redemption_yield = (yield_per_quota * redeemed_quotas).round(2)

  # Generate dates
  request_date = base_date + rand(0..180).days

  # Determine if redemption is completed, pending liquidation, or pending cotization
  status_rand = rand(100)

  cotization_date = if status_rand < 85 # 85% have cotization
                      request_date + rand(1..2).days
                    else
                      nil
                    end

  liquidation_date = if cotization_date && status_rand < 70 # 70% fully completed
                       cotization_date + rand(2..5).days
                     else
                       nil
                     end

  {
    fund_investment_id: fund_investment.id,
    redeemed_liquid_value: redeemed_liquid_value,
    redeemed_quotas: redeemed_quotas.round(6),
    redemption_yield: redemption_yield,
    redemption_type: redemption_type,
    request_date: request_date,
    cotization_date: cotization_date,
    liquidation_date: liquidation_date
  }
end

# Base date for generating redemptions (starting from mid-2025)
base_date = Date.new(2025, 6, 1)

# Get all fund investments
fund_investments = FundInvestment.all.to_a

if fund_investments.empty?
  puts "⚠️  No fund investments found. Please run fund_investments seed first."
  exit
end

puts "Found #{fund_investments.count} fund investments"

# Generate redemptions
redemptions_data = []
redemption_count_per_investment = [2, 2, 2, 3, 3, 3, 4, 4, 5] # Weighted distribution

fund_investments.each_with_index do |fund_investment, idx|
  # Skip if fund has no quotas
  next if fund_investment.total_quotas_held.to_f <= 0

  # Generate 2-5 redemptions per fund investment
  num_redemptions = redemption_count_per_investment.sample

  num_redemptions.times do |i|
    # Spread redemptions over time
    time_offset = i * 30 # 30 days apart on average
    redemptions_data << generate_redemption(
      fund_investment,
      idx * 10 + i,
      base_date + time_offset.days
    )
  end
rescue StandardError => e
  puts "⚠️  Error generating redemption for fund_investment #{fund_investment.id}: #{e.message}"
end

puts "Generated #{redemptions_data.count} redemptions"

# Create redemptions in batches
batch_size = 50
redemptions_data.each_slice(batch_size).with_index do |batch, batch_idx|
  Redemption.insert_all(batch)
  puts "✓ Created batch #{batch_idx + 1} (#{batch.size} redemptions)"
rescue StandardError => e
  puts "⚠️  Error creating batch #{batch_idx + 1}: #{e.message}"
end

# Print summary statistics
total_redemptions = Redemption.count
completed = Redemption.completed.count
pending_liquidation = Redemption.pending_liquidation.count
pending_cotization = Redemption.pending_cotization.count

puts "\n" + "="*60
puts "Redemptions Seed Summary"
puts "="*60
puts "Total redemptions created: #{total_redemptions}"
puts "  - Completed: #{completed} (#{(completed.to_f / total_redemptions * 100).round(1)}%)"
puts "  - Pending liquidation: #{pending_liquidation} (#{(pending_liquidation.to_f / total_redemptions * 100).round(1)}%)"
puts "  - Pending cotization: #{pending_cotization} (#{(pending_cotization.to_f / total_redemptions * 100).round(1)}%)"
puts "\nRedemption types:"
puts "  - Partial: #{Redemption.by_type('partial').count}"
puts "  - Total: #{Redemption.by_type('total').count}"
puts "  - Scheduled: #{Redemption.by_type('scheduled').count}"
puts "  - Emergency: #{Redemption.by_type('emergency').count}"

# Calculate total values
total_redeemed = Redemption.sum(:redeemed_liquid_value)
total_yield = Redemption.sum(:redemption_yield)
avg_yield_percentage = total_yield / (total_redeemed - total_yield) * 100

puts "\nFinancial summary:"
puts "  - Total redeemed value: R$ #{total_redeemed.to_f.round(2)}"
puts "  - Total yield: R$ #{total_yield.to_f.round(2)}"
puts "  - Average yield: #{avg_yield_percentage.round(2)}%"
puts "="*60

puts "\n✓ Redemptions seed completed successfully!"
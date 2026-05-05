class Groups::RecentActivityComponent < ApplicationComponent
  renders_many :items, Blocks::ActivityItemComponent

  def initialize(title:, action: nil, columns: 1)
    @title   = title
    @action  = action
    @columns = columns
  end

  def empty?
    items.empty?
  end
end
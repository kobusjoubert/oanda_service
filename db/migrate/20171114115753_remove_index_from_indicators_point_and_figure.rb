class RemoveIndexFromIndicatorsPointAndFigure < ActiveRecord::Migration[5.1]
  def self.up
    remove_index :indicators_point_and_figures, name: 'index_indicators_point_and_figures_unique'
  end

  def self.down
    add_index :indicators_point_and_figures, [:instrument, :granularity, :box_size, :reversal_amount, :candle_at], unique: true, name: 'index_indicators_point_and_figures_unique'
  end
end

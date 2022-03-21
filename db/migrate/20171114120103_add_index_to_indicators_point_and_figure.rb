class AddIndexToIndicatorsPointAndFigure < ActiveRecord::Migration[5.1]
  def self.up
    add_index :indicators_point_and_figures, [:instrument, :granularity, :box_size, :reversal_amount, :box_price, :candle_at], unique: true, name: 'index_indicators_point_and_figures_unique'
  end

  def self.down
    remove_index :indicators_point_and_figures, name: 'index_indicators_point_and_figures_unique'
  end
end

class AddIndexToIndicatorsPointAndFigureE < ActiveRecord::Migration[5.1]
  def self.up
    add_index :indicators_point_and_figures, [:instrument, :granularity, :box_size, :reversal_amount, :high_low_close, :candle_at, :xo, :xo_box_price, :xo_length, :trend, :trend_box_price, :trend_length], unique: true, name: 'index_indicators_point_and_figures_unique'
  end

  def self.down
    remove_index :indicators_point_and_figures, name: 'index_indicators_point_and_figures_unique'
  end
end

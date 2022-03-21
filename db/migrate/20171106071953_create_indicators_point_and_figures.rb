class CreateIndicatorsPointAndFigures < ActiveRecord::Migration[5.1]
  def change
    create_table :indicators_point_and_figures do |t|
      t.string :instrument
      t.integer :granularity
      t.integer :box_size
      t.integer :reversal_amount
      t.integer :trend
      t.integer :trend_length
      t.integer :pattern
      t.datetime :candle_at

      t.timestamps
    end

    add_index :indicators_point_and_figures, [:instrument, :granularity, :box_size, :reversal_amount, :candle_at], unique: true, name: 'index_indicators_point_and_figures_unique'
    add_index :indicators_point_and_figures, :trend_length
  end
end

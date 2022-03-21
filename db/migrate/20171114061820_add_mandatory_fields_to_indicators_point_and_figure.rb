class AddMandatoryFieldsToIndicatorsPointAndFigure < ActiveRecord::Migration[5.1]
  def self.up
    change_column :indicators_point_and_figures, :instrument, :string, null: false
    change_column :indicators_point_and_figures, :granularity, :integer, null: false
    change_column :indicators_point_and_figures, :box_size, :integer, null: false
    change_column :indicators_point_and_figures, :reversal_amount, :integer, null: false
    change_column :indicators_point_and_figures, :trend, :integer, null: false
    change_column :indicators_point_and_figures, :trend_length, :integer, null: false
    change_column :indicators_point_and_figures, :candle_at, :datetime, null: false
  end

  def self.down
    change_column :indicators_point_and_figures, :instrument, :string
    change_column :indicators_point_and_figures, :granularity, :integer
    change_column :indicators_point_and_figures, :box_size, :integer
    change_column :indicators_point_and_figures, :reversal_amount, :integer
    change_column :indicators_point_and_figures, :trend, :integer
    change_column :indicators_point_and_figures, :trend_length, :integer
    change_column :indicators_point_and_figures, :candle_at, :datetime
  end
end

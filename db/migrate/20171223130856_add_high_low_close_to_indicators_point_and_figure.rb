class AddHighLowCloseToIndicatorsPointAndFigure < ActiveRecord::Migration[5.1]
  def change
    add_column :indicators_point_and_figures, :high_low_close, :integer, null: false
  end
end

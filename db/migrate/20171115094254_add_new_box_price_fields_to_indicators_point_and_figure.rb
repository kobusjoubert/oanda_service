class AddNewBoxPriceFieldsToIndicatorsPointAndFigure < ActiveRecord::Migration[5.1]
  def change
    add_column :indicators_point_and_figures, :xo, :integer, null: false
    add_column :indicators_point_and_figures, :xo_length, :integer, null: false
    add_column :indicators_point_and_figures, :xo_box_price, :integer, null: false
    add_column :indicators_point_and_figures, :trend_box_price, :integer, null: false
  end
end

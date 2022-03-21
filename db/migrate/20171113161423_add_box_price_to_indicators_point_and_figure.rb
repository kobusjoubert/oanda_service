class AddBoxPriceToIndicatorsPointAndFigure < ActiveRecord::Migration[5.1]
  def change
    add_column :indicators_point_and_figures, :box_price, :integer
  end
end

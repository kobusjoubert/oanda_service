class RemoveBoxPriceFromIndicatorsPointAndFigure < ActiveRecord::Migration[5.1]
  def self.up
    remove_column :indicators_point_and_figures, :box_price
  end

  def self.down
    add_column :indicators_point_and_figures, :box_price, :integer
  end
end

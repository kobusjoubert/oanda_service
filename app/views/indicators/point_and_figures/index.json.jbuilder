json.data do
  json.array! @indicators_point_and_figures do |indicators_point_and_figure|
    json.type 'indicators_point_and_figure'
    json.id indicators_point_and_figure.id
    json.attributes do
      json.extract! indicators_point_and_figure, :instrument, :granularity, :box_size, :reversal_amount, :high_low_close, :xo, :xo_length, :xo_box_price, :xo_price, :trend, :trend_length, :trend_box_price, :trend_price, :pattern
      json.candle_at indicators_point_and_figure.candle_at.utc.iso8601(8)
      json.created_at indicators_point_and_figure.created_at.utc.iso8601(8)
      json.updated_at indicators_point_and_figure.updated_at.utc.iso8601(8)
    end
  end
end

# NOTE:
#
#   Rendering everything inline as above in index.json.jbuilder without using partials takes anywhere from 0.5 to 1 second.
#   Rendering 100 partials takes anywhere from 1 to 3 seconds.
#
# json.data do
#   json.array! @indicators_point_and_figures, partial: 'indicators/point_and_figures/indicators_point_and_figure', as: :indicators_point_and_figure
# end

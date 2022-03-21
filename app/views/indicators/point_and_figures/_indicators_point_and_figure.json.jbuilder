json.type 'indicators_point_and_figure'
json.id indicators_point_and_figure.id
json.attributes do
  json.extract! indicators_point_and_figure, :instrument, :granularity, :box_size, :reversal_amount, :high_low_close, :xo, :xo_length, :xo_box_price, :xo_price, :trend, :trend_length, :trend_box_price, :trend_price, :pattern
  json.candle_at indicators_point_and_figure.candle_at.utc.iso8601(8)
  json.created_at indicators_point_and_figure.created_at.utc.iso8601(8)
  json.updated_at indicators_point_and_figure.updated_at.utc.iso8601(8)
end
# json.url indicators_point_and_figures_url(indicators_point_and_figure, format: :json)

class Indicators::PointAndFiguresController < ApplicationController
  before_action :set_indicators_point_and_figure, only: [:show, :update, :destroy]

  # GET /indicators/point_and_figure
  # GET /indicators/point_and_figure.json
  def index
    options = indicators_point_and_figure_params.dup
    options[:granularity]     ||= 'd'
    options[:box_size]        ||= '20'
    options[:reversal_amount] ||= '3'
    options[:high_low_close]  ||= 'high_low'
    options[:count]           ||= '100'
    options[:instrument].upcase!
    options[:granularity].downcase!

    granularities    = options[:granularity].split(',')
    box_sizes        = options[:box_size].split(',')
    reversal_amounts = options[:reversal_amount].split(',')
    high_low_closes  = options[:high_low_close].split(',')
    counts           = options[:count].split(',')

    ids                = []
    backtest_time      = options.delete(:backtest_time)

    granularities.size.times.each do |i|
      indicator_options = {
        instrument:      options[:instrument],
        granularity:     granularities[i],
        box_size:        box_sizes[i],
        reversal_amount: reversal_amounts[i],
        high_low_close:  high_low_closes[i]
      }

      count     = (counts[i]).to_i
      ids_scope = Indicators::PointAndFigure.where(indicator_options)
      ids_scope.where!('candle_at <= ?', Time.parse(backtest_time).utc - CANDLESTICK_GRANULARITY_IN_SECONDS[granularities[i].upcase]) if backtest_time      
      ids.push(ids_scope.order(id: :desc).limit(count).select(:id).map(&:id)).flatten!
    end

    @indicators_point_and_figures = Indicators::PointAndFigure.where(id: ids).order(candle_at: :asc, created_at: :asc)
  end

  # # GET /indicators/point_and_figure/1
  # # GET /indicators/point_and_figure/1.json
  # def show
  # end
  #
  # # POST /indicators/point_and_figure
  # # POST /indicators/point_and_figure.json
  # def create
  #   @indicators_point_and_figure = Indicators::PointAndFigure.new(indicators_point_and_figure_params)
  #
  #   if @indicators_point_and_figure.save
  #     render :show, status: :created, location: @indicators_point_and_figure
  #   else
  #     render json: @indicators_point_and_figure.errors, status: :unprocessable_entity
  #   end
  # end
  #
  # # PATCH/PUT /indicators/point_and_figure/1
  # # PATCH/PUT /indicators/point_and_figure/1.json
  # def update
  #   if @indicators_point_and_figure.update(indicators_point_and_figure_params)
  #     render :show, status: :ok, location: @indicators_point_and_figure
  #   else
  #     render json: @indicators_point_and_figure.errors, status: :unprocessable_entity
  #   end
  # end
  #
  # # DELETE /indicators/point_and_figure/1
  # # DELETE /indicators/point_and_figure/1.json
  # def destroy
  #   @indicators_point_and_figure.destroy
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_indicators_point_and_figure
    @indicators_point_and_figure = Indicators::PointAndFigure.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def indicators_point_and_figure_params
    # params.require(:indicators_point_and_figure).permit(:granularity, :box_size, :reversal_amount, :trend, :trend_length, :pattern, :candle_at)
    params.permit(:instrument, :granularity, :box_size, :reversal_amount, :high_low_close, :count, :xo, :xo_length, :xo_box_price, :trend, :trend_length, :trend_box_price, :pattern, :candle_at, :backtest_time)
  end
end

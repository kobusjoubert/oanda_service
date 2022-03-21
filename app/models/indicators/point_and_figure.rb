class Indicators::PointAndFigure < ApplicationRecord
  MAX_SHEET_POINTS  = 5_000.freeze
  MAX_SHEET_COLUMNS = 100.freeze
  MIN_UPDATE_POINTS = 400.freeze

  PATTERN_MAPPING = {
    double_top:    :b,
    double_bottom: :s
  }.freeze

  XO_SIGNAL_MAPPING = {
    x: :x,
    o: :o,
    b: :x,
    s: :o
  }.freeze

  attr_reader   :sheet, :sheet_tab_title, :xos
  attr_accessor :risk_factor, :plot_to_sheet, :initial_points_time

  enum xo: [:x, :o]
  enum trend: [:up, :down]
  enum granularity: [:s5, :s10, :s15, :s30, :m1, :m2, :m3, :m4, :m5, :m10, :m15, :m30, :h1, :h2, :h3, :h4, :h6, :h8, :h12, :d, :w, :m]
  enum high_low_close: [:high_low, :close]
  enum pattern: [
    :double_top, :double_bottom,
    :triple_top, :triple_bottom,
    :spread_triple_top, :spread_triple_bottom,
    :bullish_triangle, :bearish_triangle,
    :bullish_catapult, :bearish_catapult,
    :bearish_signal_reversal, :bullish_signal_reversal
  ]

  alias :plot_to_sheet? :plot_to_sheet

  def initialize(options = {})
    options[:granularity]     ||= :d
    options[:granularity].to_s.downcase!
    options[:box_size]        ||= 20
    options[:reversal_amount] ||= 3
    options[:high_low_close]  ||= :high_low
    options[:risk_factor]     ||= 1000 # In box sizes. Only used in analyze_points.
    options[:plot_to_sheet]   = options[:plot_to_sheet].nil? ? false : options[:plot_to_sheet]
    super
    @xos             = []
    @sheet           = INSTRUMENTS[instrument]['sheet']
    @sheet_tab_title = "#{granularity.upcase}_#{box_size} #{high_low_close.to_sym == :high_low ? 'HL' : 'C'} [#{reversal_amount}]"
    @sheet_tab_title << " (#{Rails.env.capitalize})" unless Rails.env.production?
  end

  def pip_size
    @pip_size ||= INSTRUMENTS[instrument]['pip_size']
  end

  def pip_size_increment
    @pip_size_increment ||= pip_size * 0.1
  end

  def box_size_increment
    @box_size_increment ||= (box_size / 0.1).to_i
  end

  # Convert the integer box prices back to floating price values.
  # To accomplish this we simply multiply the box price by the (pip size * 0.1).
  #
  #   box price * pip_size * 0.1 (pip_size_increment)
  #      |          |      ___|
  #      |          |     |
  #   104593 * (0.0001 * 0.1)
  #   104593 * (0.00001)           => 1.0459300000000002
  #   1.0459300000000002.round(5)  => 1.04593
  def xo_price
    @xo_price ||= begin
      round_decimal = pip_size_increment.to_s.split('.').last.size
      (xo_box_price * pip_size_increment).round(round_decimal)
    end
  end

  def trend_price
    @trend_price ||= begin
      round_decimal = pip_size_increment.to_s.split('.').last.size
      (trend_box_price * pip_size_increment).round(round_decimal)
    end
  end

  def google_key_base
    @google_key_base ||= "google:sheets:point_and_figure:#{instrument.downcase}:#{granularity.downcase}_#{box_size}:#{high_low_close}"
  end

  def sheet_tab_id
    @sheet_tab_id ||= $redis.get("#{google_key_base}:sheet_tab_id")
  end

  def sheet_tab_id=(value)
    value.nil? ? $redis.del("#{google_key_base}:sheet_tab_id") : $redis.set("#{google_key_base}:sheet_tab_id", value)
    @sheet_tab_id = value
  end

  def update_in_progress
    @update_in_progress = $redis.get("#{google_key_base}:update_in_progress") == 'true'
  end

  # Prevent any concurrent jobs from interfering.
  def update_in_progress=(value)
    value.nil? || value == false ? $redis.del("#{google_key_base}:update_in_progress") : $redis.set("#{google_key_base}:update_in_progress", value)
    @update_in_progress = value
  end

  def last_updated_candle_time
    value = $redis.get("#{google_key_base}:last_updated_candle_time")
    @last_updated_candle_time = value.nil? ? nil : Time.parse(value).utc
  end

  def last_updated_candle_time=(value)
    value.nil? || value == false ? $redis.del("#{google_key_base}:last_updated_candle_time") : $redis.set("#{google_key_base}:last_updated_candle_time", value)
    @last_updated_candle_time = value
  end

  def last_plotted_point_id
    value = $redis.get("#{google_key_base}:last_plotted_point_id")
    @last_plotted_point_id = value.nil? ? nil : value.to_i
  end

  def last_plotted_point_id=(value)
    value.nil? ? $redis.del("#{google_key_base}:last_plotted_point_id") : $redis.set("#{google_key_base}:last_plotted_point_id", value)
    @last_plotted_point_id = value.nil? ? nil : value.to_i
  end

  def initialize_and_analyze_points
    initialize_points
    analyze_points
  end

  # This method is intended to be called from Rails console to set the initial points in the DB and set up the Google sheet.
  #
  #   Indicators::PointAndFigure.new(instrument: 'EUR_USD', granularity: 'H1', box_size: 10, high_low_close: 'high_low', reversal_amount: 3, plot_to_sheet: true, initial_points_time: 5.years).initialize_points
  def initialize_points
    self.update_in_progress = true
    self.last_updated_candle_time = nil
    self.last_plotted_point_id = nil

    log 'deleting old points from db...'
    self.class.where(instrument: instrument, granularity: granularity, box_size: box_size, reversal_amount: reversal_amount, high_low_close: high_low_close).destroy_all

    log 'creating new points in db...'
    update_db
    log 'finished adding points to db!'

    plot_points if plot_to_sheet?

    log 'resuming scheduled update calls from clock...'
    self.update_in_progress = false
  rescue Exceptions::IndicatorError => e
    self.update_in_progress = false
    raise e
  end

  # This method is intended to be called on a set interval by a clock.
  #
  #   Indicators::PointAndFigure.new(instrument: 'EUR_USD', granularity: 'H1', box_size: 10, high_low_close: 'high_low', reversal_amount: 3, plot_to_sheet: true).update_points
  def update_points
    raise Exceptions::IndicatorUpdateInProgress, "#{self.class} update in progress for #{instrument} #{sheet_tab_title}" if update_in_progress?
    self.update_in_progress = true

    if update_db
      if plot_to_sheet? && sheet && sheet_tab_id && last_plotted_point_id != last_points(1, :desc).first.id
        update_google_sheet
      end
    end

    self.update_in_progress = false
  rescue Exceptions::IndicatorError => e
    self.update_in_progress = false
    raise e
  end

  # Creates the initial chart and can only be called after initialize_points has been called.
  def plot_points
    unless sheet
      log 'sheet not found, please add one to the INSTRUMENTS constant!'
      self.update_in_progress = false
      return false
    end

    # Delete the cached sheet tab ID.
    self.sheet_tab_id = nil

    # Delete the old sheet tab first if it exists.
    sheet_tab = $sheets.get_spreadsheet(sheet).sheets.select{ |sheet_tab| sheet_tab.properties.title == sheet_tab_title }.first

    if sheet_tab
      log 'deleting old sheet tab...'
      delete_sheet_request             = Google::Apis::SheetsV4::DeleteSheetRequest.new(sheet_id: sheet_tab.properties.sheet_id)
      request                          = Google::Apis::SheetsV4::Request.new(delete_sheet: delete_sheet_request)
      batch_update_spreadsheet_request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(requests: [request])
      $sheets.batch_update_spreadsheet(sheet, batch_update_spreadsheet_request)
    end

    # Create a new sheet tab.
    log 'creating new sheet tab...'

    template_sheet_id     = ''
    template_sheet_tab_id = ''
    copy_sheet_request    = Google::Apis::SheetsV4::CopySheetToAnotherSpreadsheetRequest.new(destination_spreadsheet_id: sheet)
    response              = $sheets.copy_spreadsheet(template_sheet_id, template_sheet_tab_id, copy_sheet_request)

    sheet_properties                 = Google::Apis::SheetsV4::SheetProperties.new(sheet_id: response.sheet_id, title: sheet_tab_title)
    update_sheet_properties_request  = Google::Apis::SheetsV4::UpdateSheetPropertiesRequest.new(properties: sheet_properties, fields: 'title')
    request                          = Google::Apis::SheetsV4::Request.new(update_sheet_properties: update_sheet_properties_request)
    batch_update_spreadsheet_request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(requests: [request])
    $sheets.batch_update_spreadsheet(sheet, batch_update_spreadsheet_request)

    sheet_tab = $sheets.get_spreadsheet(sheet).sheets.select{ |sheet_tab| sheet_tab.properties.title == sheet_tab_title }.first

    unless sheet_tab
      log 'sheet tab could not be created!'
      return false
    end

    # Cache new sheet tab.
    self.sheet_tab_id = sheet_tab.properties.sheet_id
    log "new sheet tab created with id #{sheet_tab.properties.sheet_id}!"

    log 'plotting points to sheet...'
    initial_google_sheet
    log 'finished plotting points to sheet!'
  end

  # This method is used only to analyze points already in the DB.
  #
  #   Indicators::PointAndFigure.new(instrument: 'EUR_USD', granularity: 'H1', box_size: 10, high_low_close: 'high_low', reversal_amount: 3, risk_factor: 10).update_points
  def analyze_points
    options = {
      instrument:      instrument,
      granularity:     granularity,
      box_size:        box_size,
      reversal_amount: reversal_amount,
      high_low_close:  high_low_close
    }

    sort = {
      candle_at: :asc,
      created_at: :asc
    }

    points = self.class.where(id: self.class.where(options).where.not(pattern: nil).order(id: :asc)).order(sort)

    trades      = []
    long_trade  = nil
    short_trade = nil

    points.each do |point|
      # Nothing to do if trade is still active and no sell signal.
      next if (long_trade && point.pattern == 'double_top') || (short_trade && point.pattern == 'double_bottom')

      # Exit long trade?
      if long_trade && point.pattern == 'double_bottom'
        profit_loss = point.xo_box_price - long_trade.xo_box_price

        trade_hash = {
          trade_type:  :long,
          profit_loss: profit_loss,
          point:       point,
          trade:       long_trade
        }

        trades << trade_hash
        long_trade = nil
      end

      # Exit short trade?
      if short_trade && point.pattern == 'double_top'
        profit_loss = short_trade.xo_box_price - point.xo_box_price if short_trade && point.pattern == 'double_top'

        trade_hash = {
          trade_type:  :short,
          profit_loss: profit_loss,
          point:       point,
          trade:       short_trade
        }

        trades << trade_hash
        short_trade = nil
      end

      # Enter long trade?
      if !long_trade && point.trend == 'up' && point.pattern == 'double_top' && point.xo_length < risk_factor
        long_trade = point.dup
      end

      # Enter short trade?
      if !short_trade && point.trend == 'down' && point.pattern == 'double_bottom' && point.xo_length < risk_factor
        short_trade = point.dup
      end
    end

    printf '-' * 100
    printf "\n"

    trades.each do |trade|
      printf "[#{trade[:trade].candle_at.to_s(:db)} -> #{trade[:point].candle_at.to_s(:db)}] "
      printf "(#{trade[:trade].xo_box_price}->#{trade[:point].xo_box_price}) "
      printf "#{trade[:trade_type][0]} "
      printf trade[:profit_loss] < 0 ? "#{trade[:profit_loss]}\t" : "+#{trade[:profit_loss]}\t"
      printf "xo_length: #{trade[:trade].xo_length}\t"
      printf "trend_length: #{trade[:trade].trend_length} "
      printf "\n"
    end

    printf '-' * 100
    printf "\n"

    total_profit_loss = 0
    total_profits     = 0
    total_losses      = 0
    total_cashflow    = 0
    total_years       = {}

    trades.each do |trade|
      total_cashflow    += trade[:profit_loss].abs
      total_profit_loss += trade[:profit_loss]
      total_profits     += trade[:profit_loss] if trade[:profit_loss] >= 0
      total_losses      += trade[:profit_loss].abs if trade[:profit_loss] < 0

      year              = trade[:point].candle_at.year
      total_years[year] ||= { total_cashflow: 0, total_profit_loss: 0, total_profits: 0, total_losses: 0, total_trades: 0 }

      total_years[year][:total_cashflow]    += trade[:profit_loss].abs
      total_years[year][:total_profit_loss] += trade[:profit_loss]
      total_years[year][:total_profits]     += trade[:profit_loss] if trade[:profit_loss] >= 0
      total_years[year][:total_losses]      += trade[:profit_loss].abs if trade[:profit_loss] < 0
      total_years[year][:total_trades]      += 1
    end

    profits_percentage = total_cashflow > 0 ? ((total_profits.to_f / total_cashflow.to_f) * 100).round : 0
    losses_percentage  = total_cashflow > 0 ? ((total_losses.to_f / total_cashflow.to_f) * 100).round : 0

    printf "\nTotal #{instrument} #{granularity.upcase} #{box_size}\n\n"
    printf "#{box_size}\n"
    printf "Total\t#{trades.size}\n"
    printf "#{total_cashflow}"
    printf "\t\t(Cashflow)\n"
    printf "#{total_profits}\t#{profits_percentage}%"
    printf "\t(Profits)\n"
    printf "#{total_losses}\t#{losses_percentage}%"
    printf "\t(Losses)\n"
    printf "#{total_profit_loss}"
    printf "\t\t(Profit Loss)\n"

    total_years.each do |year, totals|
      profits_percentage = totals[:total_cashflow] > 0 ? ((totals[:total_profits].to_f / totals[:total_cashflow].to_f) * 100).round : 0
      losses_percentage  = totals[:total_cashflow] > 0 ? ((totals[:total_losses].to_f / totals[:total_cashflow].to_f) * 100).round : 0
      printf "#{year}\t#{totals[:total_trades]}\n"
      printf "#{totals[:total_cashflow]}"
      printf "\t\t(Cashflow)\n"
      printf "#{totals[:total_profits]}\t#{profits_percentage}%"
      print "\t(Profits)\n"
      printf "#{totals[:total_losses]}\t#{losses_percentage}%"
      print "\t(Losses)\n"
      printf "#{totals[:total_profit_loss]}"
      printf "\t\t(Profit Loss)\n"
    end

    nil
  end

  def last_points(count = MIN_UPDATE_POINTS, order = :desc)
    options = {
      instrument:      instrument,
      granularity:     granularity,
      box_size:        box_size,
      reversal_amount: reversal_amount,
      high_low_close:  high_low_close
    }

    sort = {
      candle_at: order,
      created_at: order
    }

    self.class.where(id: self.class.where(options).order(id: :desc).limit(count)).order(sort).load
  end

  def last_points_before_id(id, count = MIN_UPDATE_POINTS, order = :desc)
    options = {
      instrument:      instrument,
      granularity:     granularity,
      box_size:        box_size,
      reversal_amount: reversal_amount,
      high_low_close:  high_low_close
    }

    sort = {
      candle_at: order,
      created_at: order
    }

    self.class.where(id: self.class.where(options).where('id <= ?', id).order(id: :desc).limit(count)).order(sort).load
  end

  def new_points(order = :asc)
    options = {
      instrument:      instrument,
      granularity:     granularity,
      box_size:        box_size,
      reversal_amount: reversal_amount,
      high_low_close:  high_low_close
    }

    sort = {
      candle_at: order,
      created_at: order
    }

    self.class.where(options).where('id > ?', last_plotted_point_id).order(sort).load
  end

  alias :i :initialize_points
  alias :a :analyze_points
  alias :ia :initialize_and_analyze_points
  alias :update_in_progress? :update_in_progress

  private

  def pattern_type(properties, points)
    # We need at least 3 complete xo columns!
    raise Exceptions::IndicatorError, "#{self.class} ERROR. Not enough xo columns to work with. #{instrument} #{sheet_tab_title}, xos: #{xos.size}" if points.size >= MIN_UPDATE_POINTS && xos.size < 4

    return nil unless xos[-3]
    return nil if properties[:xo_length] < reversal_amount + 1

    previous_price = xos[-3].last.keys[0]

    case properties[:xo]
    when :x
      return nil if xos[-3].last[previous_price][:xo] != :x
      return :double_top if properties[:xo_box_price] == previous_price + box_size_increment
    when :o
      return nil if xos[-3].last[previous_price][:xo] != :o
      return :double_bottom if properties[:xo_box_price] == previous_price - box_size_increment
    end
  end

  def move_trend_box_price(properties)
    # Is there a buy or sell signal in the previous column?
    return properties[:trend_box_price] unless xos[-2].map { |price_hash| price_hash.values.last[:pattern] }.compact.any?

    case properties[:xo]
    when :x
      xos[-1].first.keys[0] - box_size_increment
    when :o
      xos[-1].first.keys[0] + box_size_increment 
    end
  end

  def add_point(properties)
    log "ADDING POINT #{properties}"
    raise Exceptions::IndicatorError, "ALERT ALERT ALERT! Too many points in the same direction! #{properties}" if properties[:xo_length] > MIN_UPDATE_POINTS
    update_xo_price_array(properties)
    self.class.create(properties)
  end

  # Update new points starting from last candle point saved.
  #
  # Check for a box increment first, then check for a box reversal. If box incremented, do not check for a box reversal.
  #
  # We work with integers because matching floating numbers to the current box prices is impossible.
  # To accomplish this we simply devide the price by the (pip size * 0.1).
  #
  #    price  / pip_size * 0.1 (pip_size_increment)
  #      |          |      |
  #   1.04593 / (0.0001 * 0.1)
  #   1.04593 / (0.00001)       => 104593.0
  #   104593.0.round            => 104593
  def update_db
    last_points = self.last_points

    last_point          = last_points.first
    initial_point       = last_points.blank?
    initial_points_from = initial_points_time || box_size.months

    build_xo_price_array(last_points)

    if initial_point
      last_xo              = :o
      last_xo_length       = 1
      last_xo_box_price    = 0
      last_trend           = :down
      last_trend_length    = 1
      last_trend_box_price = 0
      from                 = initial_points_from.ago
    else
      last_xo              = last_point.xo.to_sym
      last_xo_length       = last_point.xo_length
      last_xo_box_price    = last_point.xo_box_price
      last_trend           = last_point.trend.to_sym
      last_trend_length    = last_point.trend_length
      last_trend_box_price = last_point.trend_box_price
      from                 = last_point.candle_at.utc
    end

    options = { price: 'M', smooth: false, from: from.to_i, granularity: granularity.upcase, includeFirst: false }
    candles = oanda_instrument_client.instrument(instrument).candles(options).show['data']['attributes']
    raise Exceptions::IndicatorError, "ALERT ALERT ALERT! Candles instrument returned does not match #{instrument} #{sheet_tab_title}! candles['instrument']: #{candles['instrument']}, candles['granularity']: #{candles['granularity']}, candles['candles'].first: #{candles['candles'].first}" if candles['instrument'] != instrument
    return false if candles['candles'].empty?
    candles['candles'].pop unless candles['candles'].last['complete'] # Remove incomplete candles.
    return false if candles['candles'].empty? # raise Exceptions::IndicatorError, 'Cannot continue, no candles returned!' if candles['candles'].empty?

    candles['candles'].each do |candle|
      indicator_attributes = {
        instrument:      instrument,
        granularity:     granularity.downcase.to_sym,
        box_size:        box_size,
        reversal_amount: reversal_amount,
        high_low_close:  high_low_close,
        candle_at:       candle['time'],
        xo:              last_xo,
        xo_length:       last_xo_length,
        trend:           last_trend,
        trend_length:    last_trend_length
      }

      current_box_high     = (candle['mid']['h'].to_f / pip_size_increment).round.to_i
      current_box_low      = (candle['mid']['l'].to_f / pip_size_increment).round.to_i
      current_box_close    = (candle['mid']['c'].to_f / pip_size_increment).round.to_i

      current_xo_box_high_price  = current_box_high if current_box_high == last_xo_box_price
      current_xo_box_low_price   = current_box_low if current_box_low == last_xo_box_price
      current_xo_box_close_price = current_box_close if current_box_close == last_xo_box_price

      if current_box_high > last_xo_box_price
        current_xo_box_high_price = (current_box_high - current_box_high % box_size_increment).to_i
      end

      if current_box_high < last_xo_box_price
        current_xo_box_high_price = ((current_box_high + box_size_increment) - current_box_high % box_size_increment).to_i
      end

      if current_box_low > last_xo_box_price
        current_xo_box_low_price = (current_box_low - current_box_low % box_size_increment).to_i
      end

      if current_box_low < last_xo_box_price
        current_xo_box_low_price = ((current_box_low + box_size_increment) - current_box_low % box_size_increment).to_i
      end

      if current_box_close > last_xo_box_price
        current_xo_box_close_price = (current_box_close - current_box_close % box_size_increment).to_i
      end

      if current_box_close < last_xo_box_price
        current_xo_box_close_price = ((current_box_close + box_size_increment) - current_box_close % box_size_increment).to_i
      end

      if initial_point
        last_xo_box_price    = current_xo_box_close_price
        last_trend_box_price = current_xo_box_close_price + box_size_increment
        indicator_attributes.merge!(xo_box_price: last_xo_box_price, trend_box_price: last_trend_box_price)
        indicator_attributes.merge!(pattern: pattern_type(indicator_attributes, last_points))
        add_point(indicator_attributes)
        initial_point = false
        next
      end

      if last_xo == :o
        case high_low_close.to_sym
        when :high_low
          current_increment_box_price = current_xo_box_low_price
          current_reversal_box_price  = current_xo_box_high_price
        when :close
          current_increment_box_price = current_xo_box_close_price
          current_reversal_box_price  = current_xo_box_close_price
        end

        # Box increment!
        if current_increment_box_price < last_xo_box_price
          log "BOX INCREMENT current_increment_box_price: #{current_increment_box_price}, last_xo_box_price: #{last_xo_box_price}, reversal_amount: #{reversal_amount}, box_size_increment: #{box_size_increment}, candle: #{candle}"

          (current_increment_box_price..last_xo_box_price - box_size_increment).step(box_size_increment).reverse_each do |price|
            # Trend reversal!
            if last_trend == :up && price < last_trend_box_price
              last_trend           = :down
              last_trend_box_price = xos.last.first.keys[0] + box_size_increment
              last_trend_length    = 1
            end

            last_xo_length += 1
            indicator_attributes.merge!(xo_length: last_xo_length, xo_box_price: price, trend: last_trend, trend_length: last_trend_length, trend_box_price: last_trend_box_price)
            indicator_attributes.merge!(pattern: pattern_type(indicator_attributes, last_points))

            # Move trendline!
            if indicator_attributes[:pattern] && indicator_attributes[:trend] == :down
              last_trend_box_price = move_trend_box_price(indicator_attributes)

              if last_trend_box_price != indicator_attributes[:trend_box_price]
                indicator_attributes.merge!(trend_box_price: last_trend_box_price)
              end
            end

            add_point(indicator_attributes)
          end

          last_xo_box_price = current_increment_box_price

          next
        end

        # Box reversal!
        if current_reversal_box_price >= last_xo_box_price + (reversal_amount * box_size_increment)
          log "BOX REVERSAL current_reversal_box_price: #{current_reversal_box_price}, last_xo_box_price: #{last_xo_box_price}, reversal_amount: #{reversal_amount}, box_size_increment: #{box_size_increment}, candle: #{candle}"

          last_xo        = :x
          last_xo_length = 0

          case last_trend
          when :down
            last_trend_length    += 1
            last_trend_box_price += box_size_increment if last_trend_box_price == last_xo_box_price
            last_trend_box_price -= box_size_increment
          when :up
            last_trend_length    += 1
            last_trend_box_price -= box_size_increment if last_trend_box_price == last_xo_box_price
            last_trend_box_price += box_size_increment
          end

          (last_xo_box_price + box_size_increment..current_reversal_box_price).step(box_size_increment).each do |price|
            # Trend reversal!
            if last_trend == :down && price > last_trend_box_price
              last_trend           = :up
              last_trend_box_price = last_xo_box_price
              last_trend_length    = 1
            end

            last_xo_length += 1
            indicator_attributes.merge!(xo: last_xo, xo_length: last_xo_length, xo_box_price: price, trend: last_trend, trend_length: last_trend_length, trend_box_price: last_trend_box_price)
            indicator_attributes.merge!(pattern: pattern_type(indicator_attributes, last_points))

            # Move trendline!
            if indicator_attributes[:pattern] && indicator_attributes[:trend] == :up
              last_trend_box_price = move_trend_box_price(indicator_attributes)

              if last_trend_box_price != indicator_attributes[:trend_box_price]
                indicator_attributes.merge!(trend_box_price: last_trend_box_price)
              end
            end

            add_point(indicator_attributes)
          end

          last_xo_box_price = current_reversal_box_price

          next
        end
      end

      if last_xo == :x
        case high_low_close.to_sym
        when :high_low
          current_increment_box_price = current_xo_box_high_price
          current_reversal_box_price  = current_xo_box_low_price
        when :close
          current_increment_box_price = current_xo_box_close_price
          current_reversal_box_price  = current_xo_box_close_price
        end

        # Box increment!
        if current_increment_box_price > last_xo_box_price
          log "BOX INCREMENT current_increment_box_price: #{current_increment_box_price}, last_xo_box_price: #{last_xo_box_price}, reversal_amount: #{reversal_amount}, box_size_increment: #{box_size_increment}, candle: #{candle}"

          (last_xo_box_price + box_size_increment..current_increment_box_price).step(box_size_increment).each do |price|
            # Trend reversal!
            if last_trend == :down && price > last_trend_box_price
              last_trend           = :up
              last_trend_box_price = xos.last.first.keys[0] - box_size_increment
              last_trend_length    = 1
            end

            last_xo_length += 1
            indicator_attributes.merge!(xo_length: last_xo_length, xo_box_price: price, trend: last_trend, trend_length: last_trend_length, trend_box_price: last_trend_box_price)
            indicator_attributes.merge!(pattern: pattern_type(indicator_attributes, last_points))

            # Move trendline!
            if indicator_attributes[:pattern] && indicator_attributes[:trend] == :up
              last_trend_box_price = move_trend_box_price(indicator_attributes)

              if last_trend_box_price != indicator_attributes[:trend_box_price]
                indicator_attributes.merge!(trend_box_price: last_trend_box_price)
              end
            end

            add_point(indicator_attributes)
          end

          last_xo_box_price = current_increment_box_price

          next
        end

        # Box reversal!
        if current_reversal_box_price <= last_xo_box_price - (reversal_amount * box_size_increment)
          log "BOX REVERSAL current_reversal_box_price: #{current_reversal_box_price}, last_xo_box_price: #{last_xo_box_price}, reversal_amount: #{reversal_amount}, box_size_increment: #{box_size_increment}, candle: #{candle}"

          last_xo        = :o
          last_xo_length = 0

          case last_trend
          when :down
            last_trend_length    += 1
            last_trend_box_price += box_size_increment if last_trend_box_price == last_xo_box_price
            last_trend_box_price -= box_size_increment
          when :up
            last_trend_length    += 1
            last_trend_box_price -= box_size_increment if last_trend_box_price == last_xo_box_price
            last_trend_box_price += box_size_increment
          end

          (current_reversal_box_price..last_xo_box_price - box_size_increment).step(box_size_increment).reverse_each do |price|
            # Trend reversal!
            if last_trend == :up && price < last_trend_box_price
              last_trend           = :down
              last_trend_box_price = last_xo_box_price
              last_trend_length    = 1
            end

            last_xo_length += 1
            indicator_attributes.merge!(xo: last_xo, xo_length: last_xo_length, xo_box_price: price, trend: last_trend, trend_length: last_trend_length, trend_box_price: last_trend_box_price)
            indicator_attributes.merge!(pattern: pattern_type(indicator_attributes, last_points))

            # Move trendline!
            if indicator_attributes[:pattern] && indicator_attributes[:trend] == :down
              last_trend_box_price = move_trend_box_price(indicator_attributes)

              if last_trend_box_price != indicator_attributes[:trend_box_price]
                indicator_attributes.merge!(trend_box_price: last_trend_box_price)
              end
            end

            add_point(indicator_attributes)
          end

          last_xo_box_price = current_reversal_box_price

          next
        end
      end
    end

    # Update points recursively until all latest points have been added to the DB.
    if last_updated_candle_time != Time.parse(candles['candles'].last['time']).utc
      self.last_updated_candle_time = Time.parse(candles['candles'].last['time']).utc
      log "update_points #{Time.parse(candles['candles'].first['time'])} -> #{Time.parse(candles['candles'].last['time'])}..."
      update_db
      return true
    end

    true
  end

  def initial_google_sheet
    # Read from DB and build up columns needed for the entire sheet.
    points = self.last_points(MAX_SHEET_POINTS, :asc)

    price_values        = ['', '']
    xo_values           = []
    values              = []
    rows                = []
    rows_hash           = {}
    value_requests      = []
    sheet_requests      = []
    highest_sheet_price = [points.maximum(:xo_box_price), points.maximum(:trend_box_price)].max
    lowest_sheet_price  = [points.minimum(:xo_box_price), points.minimum(:trend_box_price)].min
    chart_rows_count    = ((highest_sheet_price - lowest_sheet_price) / box_size_increment).to_i + 1
    column              = 2
    header_rows_count   = 2
    sheet_colums_count  = 2
    columns_to_add      = 0
    total_requests      = 0
    sheet_rows_count    = chart_rows_count + header_rows_count
    rows_to_add         = chart_rows_count - 1
    chart_top_row       = header_rows_count + 1
    logging_enabled     = ['development', 'backtest'].include?(Rails.env)

    # Build complete nested table array in columns (values[]).
    #
    #   [['', '', '800', '600', '400', '200'], ['Jan', '1', 'X', 'X', 'X', ''], ['Jan', '5', '', 'O', 'O', 'S']]
    #
    #    |  A  |  B  |  C  |
    #  --------------------|
    #  1 |     | Jan | Jan |
    #  --|-----------------|
    #  2 |     |  1  |  5  |
    #  --|-----------------|
    #  3 | 800 |  X  |     |
    #  --|-----------------|
    #  4 | 600 |  X  |  O  |
    #  --|-----------------|
    #  5 | 400 |  X  |  O  |
    #  --|-----------------|
    #  6 | 200 |     |  S  |
    #  --|-----------------|

    # Price column.
    chart_rows_count.times.each { |i| price_values << highest_sheet_price - (box_size_increment * i) }
    values << price_values

    # Date and X, O, B or S values.
    last_point = points.first
    last_xo    = (last_point.pattern ? PATTERN_MAPPING[last_point.pattern.to_sym] : last_point.xo).to_sym
    time       = last_point.candle_at
    xo_values  = [time.strftime('%b'), time.day]

    points.each do |point|
      # Box reversal!
      if last_xo != point.xo.to_sym
        column    += 1
        values    << xo_values
        time      = point.candle_at
        xo_values = [time.strftime('%b'), time.day]
      end

      sheet_row_index            = price_values.find_index(point.xo_box_price)
      value                      = point.pattern ? PATTERN_MAPPING[point.pattern.to_sym] : point.xo
      xo_values[sheet_row_index] = value.to_s.upcase

      rows_hash[point.trend_box_price] ||= []

      trend_color =
        case point.trend
        when 'up'
          Sheet.cell_data_green
        when 'down'
          Sheet.cell_data_red
        end

      rows_hash[point.trend_box_price][column - 1] = trend_color
      last_xo = point.xo.to_sym
    end

    values << xo_values

    columns_to_add     = values.size - 2
    sheet_colums_count += columns_to_add

    value_range    = Google::Apis::SheetsV4::ValueRange.new(major_dimension: 'COLUMNS', range: "#{sheet_tab_title}!A1:#{sheet_colums_count.to_s_alpha.upcase}#{sheet_rows_count}", values: values)
    value_requests << value_range

    # Resize table.
    append_dimensions_request = Google::Apis::SheetsV4::AppendDimensionRequest.new(sheet_id: sheet_tab_id, dimension: 'COLUMNS', length: columns_to_add)
    request                   = Google::Apis::SheetsV4::Request.new(append_dimension: append_dimensions_request)
    sheet_requests            << request

    append_dimensions_request = Google::Apis::SheetsV4::AppendDimensionRequest.new(sheet_id: sheet_tab_id, dimension: 'ROWS', length: rows_to_add)
    request                   = Google::Apis::SheetsV4::Request.new(append_dimension: append_dimensions_request)
    sheet_requests            << request

    # Build complete nested table array in rows (rows[]).
    #
    #   [
    #     [blue, blue, blue, blue],
    #     [blue, blue, blue, blue],
    #     [red, white, white, white],
    #     [white, white, white, white],
    #     [white, white, white, green],
    #     [white, white, green, white],
    #     [white, green, white, white],
    #     [green, white, white, white],
    #   ]

    row = []
    sheet_colums_count.times { row << Sheet.cell_data_blue }
    header_rows_count.times { rows << row }

    chart_rows_count.times.each do |i|
      index            = highest_sheet_price - (box_size_increment * i)
      cell_data_row    = rows_hash[index] ? rows_hash[index].map { |cell_data_color| cell_data_color ? cell_data_color : Sheet.cell_data_white } : []
      cell_data_row[0] = Sheet.cell_format_white_right if cell_data_row.present? # Right allign price column.
      rows.append(cell_data_row)
    end

    update_cells_request_rows  = []
    rows.each { |row| update_cells_request_rows << Google::Apis::SheetsV4::RowData.new(values: row) }
    update_cells_request_start = Google::Apis::SheetsV4::GridCoordinate.new(sheet_id: sheet_tab_id, column_index: 0, row_index: 0)
    update_cells_request       = Google::Apis::SheetsV4::UpdateCellsRequest.new(rows: update_cells_request_rows, fields: 'userEnteredFormat', start: update_cells_request_start)
    request                    = Google::Apis::SheetsV4::Request.new(update_cells: update_cells_request)
    sheet_requests             << request

    batch_update_spreadsheet_request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(requests: sheet_requests) if sheet_requests.any?
    batch_update_values_request      = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new(data: value_requests, value_input_option: 'RAW') if value_requests.any?

    $sheets.batch do |s|
      if logging_enabled
        total_requests += sheet_requests.size if sheet_requests.any?
        total_requests += value_requests.size if value_requests.any?
        Sneakers.logger.info "---> total_requests: #{total_requests}"
      end

      if sheet_requests.any? && value_requests.any?
        s.batch_update_spreadsheet(sheet, batch_update_spreadsheet_request) do |response, error|
          raise error if error
          s.batch_update_values(sheet, batch_update_values_request) { |response, error| raise error if error }
        end
      end
    end

    self.last_plotted_point_id = points.last.id
  rescue Google::Apis::ClientError, Google::Apis::RateLimitError => e
    error_attributes = {
      highest_sheet_price: highest_sheet_price,
      lowest_sheet_price:  lowest_sheet_price,
      sheet_colums_count:  sheet_colums_count,
      sheet_rows_count:    sheet_rows_count,
      chart_rows_count:    chart_rows_count
    }

    log "ERROR! #{JSON.parse(e.body)['error']['status']}, #{e.message}, #{JSON.parse(e.body)}, #{error_attributes}"

    # Stop plotting to Google sheets when the sheet has been deleted.
    if e.class == Google::Apis::ClientError && JSON.parse(e.body)['error']['status'] == 'INVALID_ARGUMENT'
      sheet_tab = $sheets.get_spreadsheet(sheet).sheets.select{ |sheet_tab| sheet_tab.properties.title == sheet_tab_title }.first

      unless sheet_tab
        self.sheet_tab_id = nil
        raise Exceptions::GoogleSheetTabDeleted, "Indicators::PointAndFigure Google sheet tab #{sheet_tab_title} deleted for #{instrument}"
      end
    end
  end

  # Google Sheets API has a limit of 500 requests per 100 seconds per project, and 100 requests per 100 seconds per user.
  # https://developers.google.com/sheets/api/limits
  #
  # Exception:
  #
  #   Google::Apis::RateLimitError
  #   Insufficient tokens for quota 'WriteGroup' and limit 'USER-100s' of service 'sheets.googleapis.com' for consumer 'project_number:123456789012
  def update_google_sheet
    return unless sheet
    return unless sheet_tab_id

    infinity_cell          = 'ZZ100000'
    entire_sheet_range     = "#{sheet_tab_title}!A1:#{infinity_cell}"
    price_sheet_range      = "#{sheet_tab_title}!A:A"
    current_price_values   = []
    new_price_values       = []
    price_values           = []
    xo_values              = []
    values                 = []
    rows                   = []
    rows_hash              = {}
    value_requests         = []
    sheet_requests         = []
    total_requests         = 0
    new_columns_needed     = 0
    new_top_rows_needed    = 0
    new_bottom_rows_needed = 0
    logging_enabled        = ['development', 'backtest'].include?(Rails.env)

    last_point = self.class.find(last_plotted_point_id)
    raise Exceptions::IndicatorError, "No last point found in DB for #{instrument} sheet tab #{sheet_tab_title}" unless last_point

    last_points = self.last_points_before_id(last_point.id, last_point.xo_length, :asc)
    new_points  = self.new_points(:asc)

    sheet_tab      = $sheets.get_spreadsheet(sheet).sheets.select{ |sheet_tab| sheet_tab.properties.title == sheet_tab_title }.first
    sheet_table    = $sheets.get_spreadsheet_values(sheet, price_sheet_range)
    raise Exceptions::IndicatorError, "No sheet values yet for #{instrument} sheet tab #{sheet_tab_title}, please initialize the sheet with some values first by calling the initialize_points method." if sheet_table.values.empty?
    total_requests += 2

    # Sheet properties.
    sheet_rows_count     = sheet_tab.properties.grid_properties.row_count
    sheet_colums_count   = sheet_tab.properties.grid_properties.column_count
    header_rows_count    = sheet_tab.properties.grid_properties.frozen_row_count
    header_columns_count = sheet_tab.properties.grid_properties.frozen_column_count
    chart_colums_count   = sheet_colums_count - header_columns_count
    chart_rows_count     = sheet_rows_count - header_rows_count

    # Build up current price column.
    #
    # current_price_values
    #
    #   ['', '', '118400', '118200', '118000', '117800', '117600', '117400']
    #
    # Entire sheet_table.values
    #
    #   [['', 'Oct', 'Oct', 'Oct'], ['', '18', '19', '24'], ['118400', 'X'], ['118200', 'X', 'O'], ['118000', 'X', 'O', 'X'], ['117800', 'X', 'O', 'X'], ['117600', '', 'O', 'X'], ['117400', '', 'O']]
    #
    # Price sheet_table.values
    #
    #   [[], [], ['118400'], ['118200'], ['118000'], ['117800'], ['117600'], ['117400']]
    sheet_table.values.each_with_index do |row, i|
      price_value = row[0].present? ? row[0].to_i : ''
      current_price_values << price_value
    end

    if current_price_values[header_rows_count] == '' || current_price_values[-1] == ''
      raise Exceptions::IndicatorError, "Something wrong with the current price column for #{instrument} sheet tab #{sheet_tab_title}. The last row or row #{header_rows_count + 1} does not have a price value."
    end

    price_values                = current_price_values.dup
    current_highest_sheet_price = current_price_values[header_rows_count].to_i
    current_lowest_sheet_price  = current_price_values[-1].to_i
    new_highest_sheet_price     = ([current_highest_sheet_price, new_points.maximum(:xo_box_price), new_points.maximum(:trend_box_price)].max).to_i
    new_lowest_sheet_price      = ([current_lowest_sheet_price, new_points.minimum(:xo_box_price), new_points.minimum(:trend_box_price)].min).to_i

    # Did the price column change?
    #
    # Build new price_values array.
    # Determine how many top and bottom rows we need.
    if new_highest_sheet_price != current_highest_sheet_price || new_lowest_sheet_price != current_lowest_sheet_price
      new_top_rows_needed    = ((new_highest_sheet_price - current_highest_sheet_price) / box_size_increment).to_i if new_highest_sheet_price > current_highest_sheet_price
      new_bottom_rows_needed = ((current_lowest_sheet_price - new_lowest_sheet_price) /  box_size_increment).to_i if new_lowest_sheet_price < current_lowest_sheet_price

      # new_price_values
      #
      #   ['', '', '118600', '118400', '118200', '118000', '117800', '117600', '117400', '117200']
      header_rows_count.times.each { new_price_values << '' }

      (new_lowest_sheet_price..new_highest_sheet_price).step(box_size_increment) do |price|
        new_price_values.insert(header_rows_count, price)
      end

      price_values   = new_price_values.dup
      price_column   = [new_price_values]
      value_range    = Google::Apis::SheetsV4::ValueRange.new(major_dimension: 'COLUMNS', range: "#{sheet_tab_title}!A:A", values: price_column)
      value_requests << value_range
    end

    # Do we need new rows at the top?
    if new_top_rows_needed > 0
      dimension_range           = Google::Apis::SheetsV4::DimensionRange.new(sheet_id: sheet_tab_id, dimension: 'ROWS', start_index: header_rows_count, end_index: header_rows_count + new_top_rows_needed)
      insert_dimensions_request = Google::Apis::SheetsV4::InsertDimensionRequest.new(range: dimension_range, inherit_from_before: false)
      request                   = Google::Apis::SheetsV4::Request.new(insert_dimension: insert_dimensions_request)
      sheet_requests            << request

      # Remove previous column trend box formatting.
      update_cells_request_format = Google::Apis::SheetsV4::CellFormat.new(background_color: Sheet.white)
      update_cells_request_cells  = Google::Apis::SheetsV4::CellData.new(user_entered_format: update_cells_request_format)
      update_cells_request_rows   = Google::Apis::SheetsV4::RowData.new(values: [update_cells_request_cells])
      update_cells_request_range  = Google::Apis::SheetsV4::GridRange.new(sheet_id: sheet_tab_id, start_column_index: header_columns_count, end_column_index: sheet_colums_count, start_row_index: header_rows_count, end_row_index: header_rows_count + new_top_rows_needed)
      update_cells_request        = Google::Apis::SheetsV4::UpdateCellsRequest.new(rows: [update_cells_request_rows], fields: 'userEnteredFormat', range: update_cells_request_range)
      request                     = Google::Apis::SheetsV4::Request.new(update_cells: update_cells_request)
      sheet_requests              << request
    end    

    # Do we need new rows at the bottom?
    if new_bottom_rows_needed > 0
      append_dimensions_request = Google::Apis::SheetsV4::AppendDimensionRequest.new(sheet_id: sheet_tab_id, dimension: 'ROWS', length: new_bottom_rows_needed)
      request                   = Google::Apis::SheetsV4::Request.new(append_dimension: append_dimensions_request)
      sheet_requests            << request

      # Remove previous column trend box formatting.
      update_cells_request_format = Google::Apis::SheetsV4::CellFormat.new(background_color: Sheet.white)
      update_cells_request_cells  = Google::Apis::SheetsV4::CellData.new(user_entered_format: update_cells_request_format)
      update_cells_request_rows   = Google::Apis::SheetsV4::RowData.new(values: [update_cells_request_cells])
      update_cells_request_range  = Google::Apis::SheetsV4::GridRange.new(sheet_id: sheet_tab_id, start_column_index: header_columns_count, end_column_index: sheet_colums_count, start_row_index: sheet_rows_count + new_top_rows_needed, end_row_index: sheet_rows_count + new_top_rows_needed + new_bottom_rows_needed)
      update_cells_request        = Google::Apis::SheetsV4::UpdateCellsRequest.new(rows: [update_cells_request_rows], fields: 'userEnteredFormat', range: update_cells_request_range)
      request                     = Google::Apis::SheetsV4::Request.new(update_cells: update_cells_request)
      sheet_requests              << request
    end

    # Date and X, O, B or S values for current last plotted column.
    last_points.each do |point|
      if point.xo_length == 1
        time         = point.candle_at
        xo_values[0] = time.strftime('%b')
        xo_values[1] = time.day
      end

      sheet_row_index            = price_values.find_index(point.xo_box_price)
      value                      = point.pattern ? PATTERN_MAPPING[point.pattern.to_sym] : point.xo
      xo_values[sheet_row_index] = value.to_s.upcase

      rows_hash[point.trend_box_price] ||= []

      trend_color =
        case point.trend
        when 'up'
          Sheet.cell_data_green
        when 'down'
          Sheet.cell_data_red
        end

      rows_hash[point.trend_box_price][0] = trend_color
    end

    # Date and X, O, B or S values for new columns to plot.
    new_points.each do |point|
      # Box reversal!
      if point.xo_length == 1
        new_columns_needed += 1
        values    << xo_values if xo_values.any?
        time      = point.candle_at
        xo_values = [time.strftime('%b'), time.day]
      end

      sheet_row_index            = price_values.find_index(point.xo_box_price)
      value                      = point.pattern ? PATTERN_MAPPING[point.pattern.to_sym] : point.xo
      xo_values[sheet_row_index] = value.to_s.upcase

      rows_hash[point.trend_box_price] ||= []

      trend_color =
        case point.trend
        when 'up'
          Sheet.cell_data_green
        when 'down'
          Sheet.cell_data_red
        end

      rows_hash[point.trend_box_price][new_columns_needed] = trend_color
    end

    values         << xo_values
    value_range    = Google::Apis::SheetsV4::ValueRange.new(major_dimension: 'COLUMNS', range: "#{sheet_tab_title}!#{sheet_colums_count.to_s_alpha.upcase}1:#{(sheet_colums_count + new_columns_needed).to_s_alpha.upcase}#{sheet_rows_count + new_top_rows_needed + new_bottom_rows_needed}", values: values)
    value_requests << value_range

    # Do we need new columns?
    if new_columns_needed > 0
      current_last_column       = sheet_colums_count
      new_last_column           = sheet_colums_count + new_columns_needed
      append_dimensions_request = Google::Apis::SheetsV4::AppendDimensionRequest.new(sheet_id: sheet_tab_id, dimension: 'COLUMNS', length: new_columns_needed)
      request                   = Google::Apis::SheetsV4::Request.new(append_dimension: append_dimensions_request)
      sheet_requests            << request

      # Clear all formatting except for the header rows.
      update_cells_request_format = Google::Apis::SheetsV4::CellFormat.new(background_color: Sheet.white)
      update_cells_request_cell   = Google::Apis::SheetsV4::CellData.new(user_entered_format: update_cells_request_format)
      update_cells_request_cells  = Array.new(new_columns_needed, update_cells_request_cell)
      update_cells_request_rows   = Google::Apis::SheetsV4::RowData.new(values: update_cells_request_cells)
      update_cells_request_range  = Google::Apis::SheetsV4::GridRange.new(sheet_id: sheet_tab_id, start_column_index: current_last_column, end_column_index: new_last_column, start_row_index: header_rows_count, end_row_index: sheet_rows_count + new_top_rows_needed + new_bottom_rows_needed)
      update_cells_request        = Google::Apis::SheetsV4::UpdateCellsRequest.new(rows: [update_cells_request_rows], fields: 'userEnteredFormat', range: update_cells_request_range)
      request                     = Google::Apis::SheetsV4::Request.new(update_cells: update_cells_request)
      sheet_requests              << request
    end

    # Build complete nested table array in rows (rows[]).
    #
    #   [
    #     [blue, blue, blue, blue],
    #     [blue, blue, blue, blue],
    #     [red, white, white, white],
    #     [white, white, white, white],
    #     [white, white, white, green],
    #     [white, white, green, white],
    #     [white, green, white, white],
    #     [green, white, white, white],
    #   ]

    row = []
    (new_columns_needed + 1).times { row << Sheet.cell_data_blue }
    header_rows_count.times { rows << row }

    (chart_rows_count + new_top_rows_needed + new_bottom_rows_needed).times.each do |i|
      index         = new_highest_sheet_price - (box_size_increment * i)
      cell_data_row = rows_hash[index] ? rows_hash[index].map { |cell_data_color| cell_data_color ? cell_data_color : Sheet.cell_data_white } : []
      rows.append(cell_data_row)
    end

    update_cells_request_rows  = []
    rows.each { |row| update_cells_request_rows << Google::Apis::SheetsV4::RowData.new(values: row) }
    update_cells_request_start = Google::Apis::SheetsV4::GridCoordinate.new(sheet_id: sheet_tab_id, column_index: sheet_colums_count - 1, row_index: 0)
    update_cells_request       = Google::Apis::SheetsV4::UpdateCellsRequest.new(rows: update_cells_request_rows, fields: 'userEnteredFormat', start: update_cells_request_start)
    request                    = Google::Apis::SheetsV4::Request.new(update_cells: update_cells_request)
    sheet_requests             << request

    batch_update_spreadsheet_request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(requests: sheet_requests) if sheet_requests.any?
    batch_update_values_request      = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new(data: value_requests, value_input_option: 'RAW') if value_requests.any?

    $sheets.batch do |s|
      if sheet_requests.any? && value_requests.any?
        s.batch_update_spreadsheet(sheet, batch_update_spreadsheet_request) do |response, error|
          raise error if error
          s.batch_update_values(sheet, batch_update_values_request) { |response, error| raise error if error }
        end

        next
      end

      if sheet_requests.any?
        s.batch_update_spreadsheet(sheet, batch_update_spreadsheet_request) { |response, error| raise error if error }
      end

      if value_requests.any?
        s.batch_update_values(sheet, batch_update_values_request) { |response, error| raise error if error }
      end

      if logging_enabled
        total_requests += sheet_requests.size if sheet_requests.any?
        total_requests += value_requests.size if value_requests.any?
        Sneakers.logger.info "---> total_requests: #{total_requests}"
      end
    end

    self.last_plotted_point_id = new_points.last.id
  rescue Google::Apis::ClientError, Google::Apis::RateLimitError => e
    error_attributes = {
      instrument:      instrument,
      sheet_tab_title: sheet_tab_title
    }

    Sneakers.logger.warn "ERROR! #{JSON.parse(e.body)['error']['status']}, #{e.message}, #{JSON.parse(e.body)}, #{error_attributes}"

    # Stop plotting to Google sheets when the sheet has been deleted.
    if e.class == Google::Apis::ClientError && JSON.parse(e.body)['error']['status'] == 'INVALID_ARGUMENT'
      sheet_tab = $sheets.get_spreadsheet(sheet).sheets.select{ |sheet_tab| sheet_tab.properties.title == sheet_tab_title }.first

      unless sheet_tab
        self.sheet_tab_id = nil
        raise Exceptions::GoogleSheetTabDeleted, "#{self.class} Google sheet tab #{sheet_tab_title} deleted for #{instrument}"
      end
    end
  end

  # Builds a multi dimensional array from the price records in the DB.
  # This is used to determine double top and bottom breakouts etc.
  #
  #       price
  #         |
  #         V
  #
  #   [
  #     [
  #       { 1 => { xo: :x, pattern: nil } },
  #       { 2 => { xo: :x, pattern: nil } },
  #       { 3 => { xo: :x, pattern: nil } },
  #       { 4 => { xo: :x, pattern: nil } },
  #       { 5 => { xo: :x, pattern: nil } }
  #     ],
  #     [
  #       { 4 => { xo: :o, pattern: nil } },
  #       { 3 => { xo: :o, pattern: nil } },
  #       { 2 => { xo: :o, pattern: nil } }
  #     ],
  #     [
  #       { 3 => { xo: :x, pattern: nil } },
  #       { 4 => { xo: :x, pattern: nil } },
  #       { 5 => { xo: :x, pattern: nil } }
  #     ],
  #     [
  #       { 4 => { xo: :o, pattern: nil } },
  #       { 3 => { xo: :o, pattern: nil } },
  #       { 2 => { xo: :o, pattern: nil } }
  #     ],
  #     [
  #       { 3 => { xo: :x, pattern: nil } },
  #       { 4 => { xo: :x, pattern: nil } },
  #       { 5 => { xo: :x, pattern: nil } },
  #       { 6 => { xo: :x, pattern: :double_top } },
  #       { 7 => { xo: :x, pattern: nil } }
  #     ]
  #   ]
  def build_xo_price_array(points)
    @xos    = []
    xs      = []
    os      = []
    points  = points.dup.reverse
    last_xo = points.first.xo if points.any?

    points.each do |point|
      case point.xo.to_sym
      when :x
        price_hash = { point.xo_box_price => { xo: :x, pattern: point.pattern } }
        xs << price_hash

        if last_xo != point.xo
          @xos << os if os.any?
          os = []
        end
      when :o
        price_hash = { point.xo_box_price => { xo: :o, pattern: point.pattern } }
        os << price_hash

        if last_xo != point.xo
          @xos << xs if xs.any?
          xs = []
        end
      end

      last_xo = point.xo
    end

    @xos << xs if xs.any?
    @xos << os if os.any?
    xs = []
    os = []
    @xos
  end

  def update_xo_price_array(properties)
    # Initial point has no xos yet.
    if @xos.blank?
      price_hash = { properties[:xo_box_price] => { xo: properties[:xo], pattern: properties[:pattern] } }
      @xos << [price_hash]
      return @xos
    end

    price_hash = { properties[:xo_box_price] => { xo: properties[:xo], pattern: properties[:pattern] } }

    @xos.last << price_hash if properties[:xo_length] > 1
    @xos << [price_hash] if properties[:xo_length] == 1
    @xos
  end

  def log(message)
    puts '_' * 100
    puts ''
    puts "---> #{instrument} #{sheet_tab_title} #{message}"
    puts '_' * 100
  end
end

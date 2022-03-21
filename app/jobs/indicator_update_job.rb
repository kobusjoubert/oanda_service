class IndicatorUpdateJob < ApplicationJob
  from_queue :qs_indicator_update, timeout_job_after: 60

  def work(msg)
    data = JSON.parse(msg)
    update_indicator(data) ? ack! : requeue!
  rescue Timeout::Error, ActiveRecord::ConnectionTimeoutError => e
    unlock_indicator_update_in_progress(data)
    Sneakers.logger.error "TIMEOUT ERROR! IndicatorUpdateJob. #{data}, EXCEPTION: #{e.inspect}"
    requeue!
  rescue Exceptions::GoogleSheetTabDeleted => e
    unlock_indicator_update_in_progress(data)
    Sneakers.logger.error "GOOGLE SHEET ERROR! IndicatorUpdateJob. #{data}, EXCEPTION: #{e.inspect}"
    ack!
  rescue Exceptions::IndicatorUpdateInProgress => e
    unlock_indicator_update_in_progress(data)
    Sneakers.logger.error "INDICATOR UPDATE IN PROGRESS! IndicatorUpdateJob. #{data}, EXCEPTION: #{e.inspect}"
    ack!
  end

  private

  def update_indicator(data)
    data.deep_symbolize_keys!
    attributes = data[:options]
    Object.const_get("Indicators::#{data[:indicator].classify}").new(attributes).send(data[:action])
    true
  end

  def unlock_indicator_update_in_progress(data)
    data.deep_symbolize_keys!
    attributes = data[:options]
    google_key_base = Object.const_get("Indicators::#{data[:indicator].classify}").new(attributes).google_key_base
    $redis.del("#{google_key_base}:update_in_progress")
    true
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  attr_reader :oanda_instrument_client

  def initialize(options = {})
    super(options)
    @oanda_instrument_client = OandaInstrumentApi.new(email: 'oanda_service@translate3d.com', authentication_token: ENV['OANDA_INSTRUMENT_AUTHENTICATION_TOKEN'], environment: ENV['RAILS_ENV'] || 'development')
  end
end

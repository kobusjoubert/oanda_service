Rails.application.config.after_initialize do
  require 'bunny'

  config = YAML.load(ERB.new(File.read("#{Rails.root}/config/rabbitmq.yml")).result)[Rails.env]

  $rabbitmq_connection = Bunny.new(config['url_publisher'])
  $rabbitmq_connection.start
  $rabbitmq_channel = $rabbitmq_connection.create_channel
  $rabbitmq_exchange = $rabbitmq_channel.direct('oanda_app', durable: true)
end

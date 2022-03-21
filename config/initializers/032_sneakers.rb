require 'sneakers'
require 'sneakers/handlers/maxretry'
require 'sneakers/metrics/logging_metrics'

config = YAML.load(ERB.new(File.read("#{Rails.root}/config/rabbitmq.yml")).result)[Rails.env]

# RabbitMQ Worker.
sneakers_options_worker = {
  connection: Bunny.new(config['url_consumer']),
  amqp: config['url_consumer'],
  env: Rails.env, # Worker environment.
  workers: config['workers_per_cpu'].to_i,
  threads: config['worker_threads_per_cpu'].to_i,
  prefetch: config['worker_threads_per_cpu'].to_i,
  timeout_job_after: 5,
  handler: Sneakers::Handlers::Maxretry,
  heartbeat: 2,
  exchange: 'oanda_app',
  metrics: Sneakers::Metrics::LoggingMetrics.new,
  log: ENV['LOG_OUTPUT'] || $stdout
}

Sneakers.configure(sneakers_options_worker)
Sneakers.logger.level = Logger::INFO

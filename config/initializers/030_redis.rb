Rails.application.config.after_initialize do
  config = YAML.load(ERB.new(File.read("#{Rails.root}/config/redis.yml")).result)[Rails.env]

  $redis = Redis.new(url: config['url'])
end

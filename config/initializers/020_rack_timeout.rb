if Rails.env.production?
  Rack::Timeout.timeout = 20
else
  Rails.configuration.middleware.delete Rack::Timeout
end

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

ruby '2.4.5'

gem 'dotenv-rails', groups: [:development, :backtest, :test], require: 'dotenv/rails-now'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.4'
gem 'pg', '~> 0.18'
gem 'redis', '~> 3.3'
gem 'bunny', '~> 2.9'
gem 'sneakers', '~> 2.7'
gem 'puma', '~> 3.7'
gem 'rack-timeout', '~> 0.4'

gem 'jbuilder', '~> 2.5'
gem 'devise', '~> 4.3'
gem 'simple_token_authentication', '~> 1.15'
gem 'attr_encrypted', '~> 3.1'
gem 'http-exceptions_parser', '~> 0.1'
gem 'oanda_instrument_api', '2.0.2', git: 'https://github.com/kobusjoubert/oanda_instrument_api.git'
gem 'google-api-client', '0.17.1'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :development, :backtest, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development, :backtest do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

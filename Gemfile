# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.6.5"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.0.3.3", ">= 6.0.3.3"
# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Use Puma as the app server
gem "puma", ">= 4.3.5"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.10.0"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.2", require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "debase", "~> 0.2.4"
  gem "dotenv-rails"
  gem "readapt", "~> 1.1"
  gem "rswag-specs"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "ruby-debug-ide", "~> 0.7.2"
end

group :development do
  gem "guard"
  gem "guard-rspec"
  gem "listen", ">= 3.0.5", "< 3.2"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

group :test do
  gem "rspec-rails", "~> 4.0"
  gem "database_cleaner"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "devise-jwt", "~> 0.6.0"

gem "rack", ">= 2.2.3"
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem "rack-cors", "~> 1.1.1"

gem "ancestry", "~> 3.1.0"
gem "acts_as_list", "~> 1.0.1"
gem "analytics-ruby", "~> 2.2.8", require: "segment/analytics"

gem "newrelic_rpm"
gem "airbrake"
gem "aws-sdk-rails"
gem "recaptcha"
gem "websocket-extensions", ">= 0.1.5"

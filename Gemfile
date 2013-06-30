source 'https://rubygems.org'

gem 'gepetto_hooks', '>= 0', :path => File.expand_path('.'), :require => false

gem 'rake'
# A dev database add-on is provisioned if the Ruby application has the pg gem
# in the Gemfile. This populates the DATABASE_URL environment var.
gem 'sinatra'
gem 'ruby-trello'
gem 'octokit' # github
gem 'json'
gem 'liquid'
gem 'httparty'
gem 'chronic_duration'

gem 'sinatra-activerecord'
gem 'delayed_job_active_record'
gem 'workless', '~> 1.1.1'
gem 'business_time'

group :development do
  gem 'watchr'
  gem 'hub'
  gem 'wirb'
  gem 'irbtools'
  gem 'pry'
  gem 'pry-debugger'
  gem 'yard'
  gem 'redcarpet'
  gem 'terminal-notifier'
end

group :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'sqlite3'
end

group :production do
  gem 'thin'
  gem 'pg'
end

# vim:ft=ruby

source :rubygems

gem 'rake'
# A dev database add-on is provisioned if the Ruby application has the pg gem
# in the Gemfile. This populates the DATABASE_URL environment var.
gem 'sinatra'
gem 'ruby-trello'
gem 'json'

gem 'sinatra-activerecord'
gem 'delayed_job_active_record'
gem 'workless', '~> 1.1.1'

group :development do
  gem 'watchr'
  gem 'pry'
  gem 'pry-debugger'
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

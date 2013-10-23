source 'https://rubygems.org'

gem 'gepetto_hooks', '>= 0', :path => File.expand_path('.'), :require => false

gem 'rake'
gem 'thor'

gem 'sinatra'
gem 'ruby-trello'
gem 'jira-ruby', :require => 'jira'
gem 'octokit'

gem 'json'
gem 'liquid'

gem 'sinatra-activerecord'

gem 'delayed_job_active_record'
gem 'delayed_job'
gem 'workless', '1.1.3'

gem 'business_time'

gem 'rails', '~> 3.2'

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
  # A dev database add-on is provisioned if the Ruby application has the pg gem
  # in the Gemfile. This populates the DATABASE_URL environment var.
end


if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
# vim:ft=ruby

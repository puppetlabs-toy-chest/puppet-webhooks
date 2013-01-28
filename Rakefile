$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'rake'
require 'erb'
require 'sinatra/activerecord/rake'
require 'puppet_labs/pull_request_app'
require 'delayed/tasks'
require 'puppet_labs/webhook'
if not ENV['RACK_ENV']
  ENV['RACK_ENV'] ||= 'development'
end

pwd = File.expand_path('..', __FILE__)

task :default => :help

desc 'List tasks (rake -T)'
task :help do
  sh 'rake -T'
end

# Setup the environment for the application
task :environment do
  PuppetLabs::Webhook.setup_environment(ENV['RACK_ENV'])
end

desc "IRB REPL Shell"
task :shell => :environment do
  require 'irb'
  ARGV.clear
  IRB.start
end


# Delayed Job database
namespace :db do
  desc "Create the database"
  task(:create) do
    require 'active_record'
    require 'pg'
    require 'yaml'

    dbconfig = YAML.load(ERB.new(File.read('config/database.yml')).result)
    ar_dbconfig = dbconfig[ENV['RACK_ENV']]
    ar_dbconfig_sys = ar_dbconfig.merge(
      'database' => 'postgres',
      'schema_search_path' => 'public'
    )
    # drops and create need to be performed with a connection to the 'postgres'
    # (system) database
    ActiveRecord::Base.establish_connection ar_dbconfig_sys
    # drop the old database (if it exists)
    ActiveRecord::Base.connection.drop_database ar_dbconfig['database']
    # Create the database
    ActiveRecord::Base.connection.create_database ar_dbconfig['database']
    puts "Created empty database #{ar_dbconfig['database']}"
  end

  desc "Migrate the database"
  task(:migrate => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end
end

namespace :api do
  desc "Run the server using foreman form the Heroku toolbelt"
  task :run do
    sh 'foreman start'
  end

  desc "Submit a fake pull request"
  task(:pull_request) do
    sh 'curl -i -H "Content-Type: application/json" --data "$(cat spec/unit/fixtures/example_pull_request.json)" http://localhost:5000/event/github/'
  end

  desc "Submit a fake issue"
  task(:issue) do
    sh 'curl -i -H "Content-Type: application/json" --data "$(cat spec/unit/fixtures/example_issue.json)" http://localhost:5000/event/github/'
  end
end

desc "Use watchr to auto test"
task :watchr do
  sh 'bundle exec watchr spec/watchr.rb'
end

desc "Run a web server with documentation"
task :apidoc do
  sh 'bundle exec yard server --reload'
end

namespace :jobs do
  desc "Run a delayed job worker quietly"
  task :worksilent => :environment do
    Delayed::Worker.new(:min_priority => ENV['MIN_PRIORITY'],
                        :max_priority => ENV['MAX_PRIORITY'],
                        :queues => (ENV['QUEUES'] || ENV['QUEUE'] || '').split(','),
                        :quiet => true).start
  end
end

desc "Run the examples in spec/"
task :spec do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
end

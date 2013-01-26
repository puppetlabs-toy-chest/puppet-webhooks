$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'rake'
require 'erb'
require 'sinatra/activerecord/rake'
require 'puppet_labs/pull_request_app'
require 'delayed/tasks'

ENV['RACK_ENV'] ||= 'development'
pwd = File.expand_path('..', __FILE__)

task :default => :help

desc 'List tasks (rake -T)'
task :help do
  sh 'rake -T'
end

desc 'Run example behaviors (specs)'
task :spec do
  sh 'bundle exec rspec spec'
end

# Setup the environment for the application
task :environment do
  # Note, the order of these libraries appears to be important.  In order to
  # get the worker jobs to reliably spin down, I think these need to be before
  # the job libraries.
  require 'delayed_job_active_record'
  require 'workless'
  # The rest of the libraries come after workless
  require 'puppet_labs/pull_request_job'
  require 'active_record'
  require 'active_support/core_ext'
  require 'pg'
  require 'logger'
  require 'erb'

  logger = Logger.new(STDERR)

  ActiveRecord::Base.logger = logger.clone
  ActiveRecord::Base.logger.level = Logger::ERROR

  Delayed::Worker.destroy_failed_jobs = false
  Delayed::Backend::ActiveRecord::Job.send(:include, Delayed::Workless::Scaler)
  # This is a reasonable limit to keep the worker process from running minutes
  # on end when using workless.  Failures will be logged and visible in `heroku
  # logs` and watching for PERMANENTLY removing.
  Delayed::Worker.max_attempts = 3
  Delayed::Worker.max_run_time = 10.minutes
  Delayed::Worker.logger = logger.clone
  Delayed::Worker.logger.level = Logger::INFO
  Delayed::Job.scaler = :heroku_cedar
  dbconfig = YAML.load(ERB.new(File.read('config/database.yml')).result)
  ActiveRecord::Base.establish_connection(dbconfig[ENV['RACK_ENV']])
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

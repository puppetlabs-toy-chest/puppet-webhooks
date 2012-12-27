require 'rake'
require 'delayed/tasks'

ENV['RACK_ENV'] ||= 'development'
pwd = File.expand_path('..', __FILE__)

task :default => :help

desc 'List tasks (rake -T)'
task :help do
  sh 'rake -T'
end

task :spec do
  sh 'rspec spec.rb'
end

# Setup the environment for the application
task :environment do
  require 'delayed_job_active_record'
  require 'active_record'
  require 'pg'
  require 'logger'

  conf = YAML.load_file("#{pwd}/config/database.yml")
  ActiveRecord::Base.establish_connection conf[ENV['RACK_ENV']]
end

# Delayed Job database
namespace :db do
  desc "Create the database"
  task(:create) do
    require 'active_record'
    require 'pg'
    require 'yaml'

    conf = YAML.load_file("#{pwd}/config/database.yml")
    ar_conf = conf[ENV['RACK_ENV']]
    ar_conf_sys = ar_conf.merge(
      'database' => 'postgres',
      'schema_search_path' => 'public',
    )
    # drops and create need to be performed with a connection to the 'postgres'
    # (system) database
    ActiveRecord::Base.establish_connection ar_conf_sys
    # drop the old database (if it exists)
    ActiveRecord::Base.connection.drop_database ar_conf['database']
    # Create the database
    ActiveRecord::Base.connection.create_database ar_conf['database']
    puts "Created database #{ar_conf['database']}"
  end

  desc "Migrate the database"
  task(:migrate => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end
end

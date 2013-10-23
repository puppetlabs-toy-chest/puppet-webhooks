# Note, the order of these libraries appears to be important.  In order to
# get the worker jobs to reliably spin down, I think these need to be before
# the job libraries.

require 'delayed_job_active_record'
require 'workless'
# The rest of the libraries come after workless
require 'active_record'
require 'active_support/core_ext'
require 'logger'
require 'erb'

module PuppetLabs
  class Webhook
    # Initialize application logging, delayed job behavior, and the database connection.
    #
    # @param rack_env [String] The rack environment, usually one of 'production',
    #   'test', 'development'
    def self.setup_environment(rack_env='production')
      setup_logging(rack_env)
      setup_delayed_job(rack_env)
      setup_database(rack_env)
    end

    # Initialize log configuration for activerecord and delayedjob and ensure
    # that stdout and stderr are kept flushed.
    #
    # @param rack_env [String] The rack environment, usually one of 'production',
    #   'test', 'development'
    def self.setup_logging(rack_env)
      STDOUT.sync = true
      STDERR.sync = true
      logger = Logger.new(STDERR)

      ActiveRecord::Base.logger = logger.clone
      Delayed::Worker.logger = logger.clone

      case rack_env
      when 'development', 'test'
        ActiveRecord::Base.logger.level = Logger::ERROR
        Delayed::Worker.logger.level = Logger::ERROR
      when 'production'
        ActiveRecord::Base.logger.level = Logger::ERROR
        Delayed::Worker.logger.level = Logger::INFO
      else
        raise ArgumentError, "Cannot setup logging: unknown RACK_ENV #{rack_env}"
      end
    end

    # Initialize delayed job worker configuration and the workless scaler
    #
    # @param rack_env [String] The rack environment, usually one of 'production',
    #   'test', 'development'
    def self.setup_delayed_job(rack_env)
      Delayed::Backend::ActiveRecord::Job.send(:include, Delayed::Workless::Scaler)

      case rack_env
      when 'development', 'test'
        Delayed::Job.scaler = :null
      when 'production'
        Delayed::Job.scaler = :heroku_cedar
      else
        raise ArgumentError, "Cannot setup delayed job: unknown RACK_ENV #{rack_env}"
      end

      # This is a reasonable limit to keep the worker process from running minutes
      # on end when using workless.  Failures will be logged and visible in `heroku
      # logs` and watching for PERMANENTLY removing.
      Delayed::Worker.max_attempts = 3
      Delayed::Worker.max_run_time = 10.minutes
      Delayed::Worker.destroy_failed_jobs = false
    end

    # Initialize a database connection
    #
    # @param rack_env [String] The rack environment, usually one of 'production',
    #   'test', 'development'
    def self.setup_database(rack_env)
      config = dbconfig(rack_env)
      ActiveRecord::Base.establish_connection(config[rack_env])

      # Migration for sqlite3 in memory database.
      if rack_env == 'test'
        ActiveRecord::Migration.verbose = false
        ActiveRecord::Migrator.migrate("#{File.expand_path("../../..", __FILE__)}/db/migrate")
      end
    end

    # Render the contents of config/database.yml as a hash.
    #
    # @param rack_env [String] The rack environment, usually one of 'production',
    #   'test', 'development'
    #
    # @return [Hash] The database configuration in the given environment
    def self.dbconfig(rack_env)
      YAML.load(ERB.new(File.read('config/database.yml')).result)
    end
  end
end

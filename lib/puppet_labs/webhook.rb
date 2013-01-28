# Note, the order of these libraries appears to be important.  In order to
# get the worker jobs to reliably spin down, I think these need to be before
# the job libraries.

require 'delayed_job_active_record'
require 'workless'
# The rest of the libraries come after workless
require 'puppet_labs/trello_pull_request_job'
require 'active_record'
require 'active_support/core_ext'
require 'pg'
require 'logger'
require 'erb'

module PuppetLabs
class Webhook
  ##
  # setup_environment configures the Ruby process for use with the data store
  # and logging.  This method is called from the rake tasks and reflects the
  # `:environment` task convention.  The primary responbilities are to
  # configure logging, the database connection and the delayed job framework.
  # This method is also useful when working interactively in irb or pry.
  #
  # @param rack_env [String] the rack environment defined in
  # {config/database.yml}.  Usually one of "development", "test", or
  # "production"
  def self.setup_environment(rack_env='production')
    STDOUT.sync = true
    STDERR.sync = true
    logger = Logger.new(STDERR)

    ActiveRecord::Base.logger = logger.clone
    Delayed::Worker.logger = logger.clone

    Delayed::Backend::ActiveRecord::Job.send(:include, Delayed::Workless::Scaler)

    case rack_env
    when 'test'
      ActiveRecord::Base.logger.level = Logger::ERROR
      Delayed::Worker.logger.level = Logger::ERROR
      Delayed::Job.scaler = :null
    else
      ActiveRecord::Base.logger.level = Logger::ERROR
      Delayed::Worker.logger.level = Logger::INFO
      Delayed::Job.scaler = :heroku_cedar
    end

    dbconfig = YAML.load(ERB.new(File.read('config/database.yml')).result)
    ActiveRecord::Base.establish_connection(dbconfig[rack_env])

    # Migration for sqlite3 in memory database.
    if rack_env == 'test'
      ActiveRecord::Migration.verbose = false
      ActiveRecord::Migrator.migrate("#{File.expand_path("../../..", __FILE__)}/db/migrate")
    end

    # This is a reasonable limit to keep the worker process from running minutes
    # on end when using workless.  Failures will be logged and visible in `heroku
    # logs` and watching for PERMANENTLY removing.
    Delayed::Worker.max_attempts = 3
    Delayed::Worker.max_run_time = 10.minutes
    Delayed::Worker.destroy_failed_jobs = false
  end
end
end

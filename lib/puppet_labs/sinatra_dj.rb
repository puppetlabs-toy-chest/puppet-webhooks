require 'active_record'
require 'delayed_job_active_record'
require 'erb'

module PuppetLabs
  ##
  # SinatraDJ provides helper methods meant to be mixed into a class to
  # initialize the system to a point where Delayed Jobs are able to be queued
  # using: {Delayed::Job.enqueue} PuppetLabs::PullRequestJob.new(:payload => request['payload'])
module SinatraDJ
  ##
  # initialize_dj initiailzes everything necessary to use {Delayed::Job}.
  def initialize_dj
    establish_connection(dbconfig[env['RACK_ENV']])
  end

  ##
  # queue_job takes a job object and queues it. See {Delayed::Job.enqueue} for
  # more information about the options available.
  #
  # @option options [String] :queue The DJ Queue
  def queue_job(obj, options={})
    initialize_dj
    Delayed::Job.enqueue(obj, options)
  end

  ##
  # dbconfig returns a complete database configuration from
  # `config/database.yml`.
  #
  # @return [Hash] database configuration
  def dbconfig
    YAML.load(ERB.new(read('config/database.yml')).result)
  end

  def establish_connection(config)
    ActiveRecord::Base.establish_connection(config)
  end
  private :establish_connection

  def env
    ENV
  end
  private :env

  def read(path)
    File.read(path)
  end
  private :read
end
end

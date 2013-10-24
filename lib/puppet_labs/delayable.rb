require 'active_record'
require 'delayed_job_active_record'

module PuppetLabs

  # This defines methods for tasks that can be run as delayed jobs. Objects
  # that should act as delayed jobs must implement the #perform method.
  #
  # @see https://github.com/collectiveidea/delayed_job#custom-jobs
  module Delayable

    def queue(options={:queue => queue_name})
      queue_job(self, options)
    end

    def queue_name
      'default'
    end

    # queue_job takes a job object and queues it. See {Delayed::Job.enqueue} for
    # more information about the options available.
    #
    # @option options [String] :queue The DJ Queue
    def queue_job(obj, options={})
      Delayed::Job.enqueue(obj, options)
    end
  end
end

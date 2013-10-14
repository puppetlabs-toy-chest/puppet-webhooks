require 'puppet_labs/sinatra_dj'

module PuppetLabs

  # This defines methods for tasks that can be run as delayed jobs. Objects
  # that should act as delayed jobs must implement the #perform method.
  #
  # @see https://github.com/collectiveidea/delayed_job#custom-jobs
  module Delayable
    include PuppetLabs::SinatraDJ

    def queue(options={:queue => queue_name})
      queue_job(self, options)
    end

    def queue_name
      'default'
    end
  end
end

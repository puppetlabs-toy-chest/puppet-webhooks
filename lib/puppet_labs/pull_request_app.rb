require 'json'
require 'time'
require 'sinatra/base'
require 'puppet_labs/pull_request'
require 'puppet_labs/pull_request_job'
require 'delayed_job_active_record'
require 'workless'


module PuppetLabs
  class PullRequestApp < Sinatra::Base
    configure :production do
      Delayed::Worker.max_attempts = 3
      Delayed::Backend::ActiveRecord::Job.send(:include, Delayed::Workless::Scaler)
      Delayed::Job.scaler = :heroku_cedar
    end

    get '/' do
      "Hello World!"
    end

    post '/event/pull_request' do
      pull_request = PuppetLabs::PullRequest.from_json(request['payload'])
      job = PuppetLabs::PullRequestJob.new
      job.pull_request = pull_request
      delayed_job = job.queue

      # Accepted
      # The request has been accepted for processing, but the processing has
      # not been completed. The request might or might not eventually be acted
      # upon, as it might be disallowed when processing actually takes place.
      status = 202
      headers = {'Content-Type' => 'application/json'}
      body = {
        'job_id' => delayed_job.id,
        'queue' => delayed_job.queue,
        'priority' => delayed_job.priority,
        'created_at' => delayed_job.created_at,
      }
      [status, headers, JSON.dump(body)]
    end
  end
end

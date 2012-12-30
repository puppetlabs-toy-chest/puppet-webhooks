require 'sinatra/base'
require 'puppet_labs/pull_request'
require 'puppet_labs/pull_request_job'

module PuppetLabs
  class PullRequestApp < Sinatra::Base
    get '/' do
      "Hello World!"
    end

    post '/event/pull_request' do
      pull_request = PuppetLabs::PullRequest.from_json(request['payload'])
      job = PuppetLabs::PullRequestJob.new
      job.pull_request = pull_request
      delayed_job = job.queue
    end
  end
end

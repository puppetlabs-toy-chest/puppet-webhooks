require 'json'
require 'time'
require 'sinatra/base'
require 'puppet_labs/pull_request'
require 'puppet_labs/pull_request_job'
require 'delayed_job_active_record'
require 'openssl'
require 'digest/sha1'
require 'digest/sha2'
require 'workless'
require 'logger'


module PuppetLabs
  class PullRequestApp < Sinatra::Base
    HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

    class UnauthenticatedError < StandardError; end

    helpers do
      def logger
        @logger ||= Logger.new(STDERR)
      end

      def response_headers
        @response_headers ||= {'Content-Type' => 'application/json'}
      end
    end

    configure :production do
      Delayed::Backend::ActiveRecord::Job.send(:include, Delayed::Workless::Scaler)
      Delayed::Job.scaler = :heroku_cedar
    end

    configure do
      disable :show_exceptions
      enable :logging
      Delayed::Worker.max_attempts = 3
    end

    get '/' do
      "Hello World!"
    end

    # Previous, but dead, endpoint
    post '/event/pull_request/?' do
      payload = request.form_data? ? request['payload'] : request.body.read
      json = JSON.load(payload)
      repo = "%s/%s" % [json['repository']['owner_name'],
                        json['repository']['name']]
      logger.info "#{repo} should be using /event/github instead of /event/pull_request"
      halt 204, response_headers
    end

    post '/event/travis/?' do
      headers = response_headers
      json = JSON.load(params['payload'])
      if !(secret = ENV['TRAVIS_AUTH_TOKEN'].to_s).empty?
        repo = "#{json['repository']['owner_name']}" +
               "/#{json['repository']['name']}"
        shared_secret = repo + secret
        auth_check = Digest::SHA2.hexdigest(shared_secret)
        if auth_check == env['HTTP_AUTHORIZATION']
          logger.info "[/event/travis] Authentication: SUCCESS - Digest::SHA2.hexdigest(#{repo.inspect} + TRAVIS_AUTH_TOKEN) -= #{env['HTTP_AUTHORIZATION']}"
        else
          logger.info "[/event/travis] Authentication: FAILURE - Digest::SHA2.hexdigest(#{repo.inspect} + TRAVIS_AUTH_TOKEN) != #{env['HTTP_AUTHORIZATION']}"
          logger.info "[/event/travis] Authentication failure does not prevent access. (FIXME)"
        end
      else
        logger.info "[/event/travis] Authentication: DISABLED - Please configure the TRAVIS_AUTH_TOKEN environment variable to be the string shown on your travis profile page."
      end
      body = { 'status' => 'Job processing for Travis has not yet been been implemented. ' }
      [200, headers, JSON.dump(body)]
    end

    post '/event/github/?' do
      headers = {'Content-Type' => 'application/json'}

      case event = env['HTTP_X_GITHUB_EVENT'].to_s
      when 'pull_request'
        logger.info "Handling X-Github-Event: #{event}"
      else
        logger.info "Ignoring X-Github-Event: #{event}"
        halt 204, headers
      end

      request_body = request.body.read

      # Authenticate via X-Hub-Signature
      # TODO: This could be a Sinatra filter.  See:
      # http://sinatra.restafari.org/book.html#authentication
      if !(secret = ENV['GITHUB_X_HUB_SIGNATURE_SECRET'].to_s).empty?
        # The computed SHA1 signature.  This should match the header value.
        sig_c = "sha1=#{OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, request_body)}".downcase
        # The sent SHA1 sinagure.  Expected in the X-Hub-Signature request header.
        sig_s = env['HTTP_X_HUB_SIGNATURE'].to_s.downcase
        if sig_c != sig_s
          body = {
            'message' => 'Permission denied. X-Hub-Signature header does not match body'
          }
          halt 401, headers, JSON.dump(body)
        end
        logger.info "[/event/github] Authentication: SUCCESS - X-Hub-Signature header contains a valid signature."
      end

      # If there is form data then we expect the payload in the payload parameter.
      # otherwise, we expect all of the form data on the in
      payload = if request.form_data?
        request['payload']
      else
        request_body
      end

      pull_request = PuppetLabs::PullRequest.from_json(payload)

      if pull_request.action == "opened"
        job = PuppetLabs::PullRequestJob.new
        job.pull_request = pull_request
        delayed_job = job.queue

        logger.info "Successfully queued up opened pull request #{pull_request.repo_name}/#{pull_request.number} as job #{delayed_job.id}"

        # Accepted
        # The request has been accepted for processing, but the processing has
        # not been completed. The request might or might not eventually be acted
        # upon, as it might be disallowed when processing actually takes place.
        status = 202
        body = {
          'job_id' => delayed_job.id,
          'queue' => delayed_job.queue,
          'priority' => delayed_job.priority,
          'created_at' => delayed_job.created_at,
        }
      else
        logger.info "Ignoring pull request #{pull_request.repo_name}/#{pull_request.number} because the action is #{pull_request.action}."
        body = { 'message' => 'Action has been ignored.' }
        halt 200, headers, JSON.dump(body)
      end

      [status, headers, JSON.dump(body)]
    end
  end
end

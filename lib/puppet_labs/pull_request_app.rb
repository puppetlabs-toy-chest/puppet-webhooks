require 'json'
require 'time'
require 'sinatra/base'
require 'sinatra/activerecord'
require 'puppet_labs/pull_request'
require 'puppet_labs/pull_request_job'
require 'puppet_labs/event'
require 'delayed_job_active_record'
require 'openssl'
require 'digest/sha1'
require 'digest/sha2'
require 'workless'
require 'logger'


module PuppetLabs
  class PullRequestApp < Sinatra::Base
    # config/database.yml is automatically picked up and may contain ERB.
    register Sinatra::ActiveRecordExtension
    # Authorizing Github hook events uses the HMAC_DIGEST constant.
    HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

    class UnauthenticatedError < StandardError; end

    helpers do
      def logger
        @logger ||= Logger.new(STDERR)
      end

      def response_headers
        @response_headers ||= {'Content-Type' => 'application/json'}
      end

      def authenticate!
        logger.info "[#{request.path_info}] Authenticating request: #{request}"
        if not authentic?
          status 'Authentication: FAILURE'
          body = { 'status' => status }
          logger.info "[#{request.path_info}] #{status}"
          halt 403, response_headers, JSON.dump(body) << "\n"
        end
        logger.info "[#{request.path_info}] Authentication: SUCCESS #{request}"
      end

      def authentic?
        !!(authenticate_github(request) or authenticate_travis(request))
      end

      # Authenticate via X-Hub-Signature
      # TODO: This could be a Sinatra filter.  See:
      # http://sinatra.restafari.org/book.html#authentication
      def authenticate_github(request)
        request.body.rewind
        request_body = request.body.read
        if !(secret = ENV['GITHUB_X_HUB_SIGNATURE_SECRET'].to_s).empty?
          # The computed SHA1 signature.  This should match the header value.
          sig_c = "sha1=#{OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, request_body)}".downcase
          # The sent SHA1 sinagure.  Expected in the X-Hub-Signature request header.
          sig_s = request.env['HTTP_X_HUB_SIGNATURE'].to_s.downcase
          if sig_c == sig_s
            logger.info "[#{request.path_info}] Github Authentication: SUCCESS - X-Hub-Signature header contains a valid signature."
            return true
          else
            logger.info "[#{request.path_info}] Github Authentication: FAILURE - X-Hub-Signature header contains an invalid signature."
            return false
          end
        else
          logger.info "[#{request.path_info}] Github Authentication: DISABLED - Please configure the GITHUB_X_HUB_SIGNATURE_SECRET environment variable to match the Github hook configuration."
          return false
        end
      end

      ##
      # authenticate_travis returns true if the request is authenticated as a
      # travis request.
      def authenticate_travis(request)
        json = JSON.load(request.params['payload'])
        if !(secret = ENV['TRAVIS_AUTH_TOKEN'].to_s).empty?
          repo = "#{json['repository']['owner_name']}" +
                 "/#{json['repository']['name']}"
          shared_secret = repo + secret
          auth_check = Digest::SHA2.hexdigest(shared_secret)
          if auth_check == request.env['HTTP_AUTHORIZATION']
            logger.info "[#{request.path_info}] Travis Authentication: SUCCESS - Digest::SHA2.hexdigest(#{repo.inspect} + TRAVIS_AUTH_TOKEN) -= #{env['HTTP_AUTHORIZATION']}"
            true
          else
            logger.info "[#{request.path_info}] Travis Authentication: FAILURE - Digest::SHA2.hexdigest(#{repo.inspect} + TRAVIS_AUTH_TOKEN) != #{env['HTTP_AUTHORIZATION']}"
            logger.info "[#{request.path_info}] Travis Authentication failure does not prevent access. (FIXME)"
            false
          end
        else
          logger.info "[#{request.path_info}] Travis Authentication: DISABLED - Please configure the TRAVIS_AUTH_TOKEN environment variable to be the string shown on your travis profile page."
          false
        end
      end

      ##
      # save_event saves the payload and the request for later processing.
      # @return [Event] instance of the created event
      def save_event
        event = Event.new(:name => "Event #{request.path_info}",
                          :payload => payload,
                          :request => request.to_yaml)
        event.save
        logger.info "Created event_id=#{event.id}"
        event
      end

      ##
      # Obtain the payload from the request.  If there is Form data, we expect
      # this as a string in the parameter named payload.  If there is no form
      # data, then we expect to the payload to be the body.
      def payload
        if request.form_data?
          request['payload']
        else
          request.body.rewind
          request.body.read
        end
      end
    end

    configure :production do
      ActiveRecord::Base.logger.level = Logger::INFO
      Delayed::Backend::ActiveRecord::Job.send(:include, Delayed::Workless::Scaler)
      Delayed::Job.scaler = :heroku_cedar
    end

    configure do
      disable :show_exceptions
      enable :logging
      Delayed::Worker.max_attempts = 3
    end

    before do
      authenticate!
      request.body.rewind
    end

    get '/' do
      "Hello World!"
    end

    # Previous, but dead, endpoint
    post '/event/pull_request/?' do
      json = JSON.load(payload)
      repo = "%s/%s" % [json['repository']['owner_name'],
                        json['repository']['name']]
      logger.info "#{repo} should be using /event/github instead of /event/pull_request"
      halt 204, response_headers
    end

    post '/event/travis/?' do
      save_event
      status = 'Job processing for Travis has not yet been been implemented.'
      logger.info "[#{request.path_info}] #{status}"
      body = { 'status' => status }
      [204, response_headers, JSON.dump(body)]
    end

    post '/event/github/?' do
      save_event
      payload = payload()

      case gh_event = env['HTTP_X_GITHUB_EVENT'].to_s
      when 'pull_request'
        logger.info "Handling X-Github-Event: #{gh_event}"
      else
        logger.info "Ignoring X-Github-Event: #{gh_event}"
        halt 204, response_headers
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
        halt 204, response_headers, JSON.dump(body)
      end

      [status, headers, JSON.dump(body)]
    end
  end
end

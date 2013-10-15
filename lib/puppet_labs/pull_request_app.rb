# Web application libraries
require 'json'
require 'sinatra/base'
require 'puppet_labs/event'

# Delayed job libraries
require 'active_support/core_ext'
require 'sinatra/activerecord'
require 'delayed_job_active_record'
require 'workless'

# App controllers
require 'puppet_labs/github/github_controller'

require 'logger'
require 'ostruct'

module PuppetLabs
  class PullRequestApp < Sinatra::Base
    # config/database.yml is automatically picked up and may contain ERB.
    register Sinatra::ActiveRecordExtension
    # Authorizing Github hook events uses the HMAC_DIGEST constant.

    class UnauthenticatedError < StandardError; end

    def self.logger
      @logger ||= Logger.new(STDERR, Logger::WARN)
    end

    module AppHelpers
      def logger
        @logger ||= Logger.new(STDERR, Logger::WARN)
      end

      ##
      # Log a simple INFO message using the request.path_info method.
      def log(msg)
        logger.info "[#{request.path_info}] #{msg}"
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


      ##
      # limit_events_to prunes the database, limiting to the [limit] most
      # recent events.
      def limit_events_to(limit)
        Event.order("id desc").offset(limit).each do |event|
          event.delete
        end
      end

      ##
      # save_event saves the payload and the request for later processing.
      # @option options :request The request instance
      #
      # @option options [Hash] :payload The event payload from the request.
      # This will usually be a Hash.
      #
      # @option options [Fixnum] :limit The upper limit on the number of events
      # to persist in the database.  Events older than the Nth limit event will
      # be deleted.  A limit of 100 will be used if not specified.
      #
      # @return [Event] instance of the created event
      def save_event(options={})
        request = options[:request]
        payload = options[:payload]
        limit = options[:limit] || 100

        req = OpenStruct.new(
            :method => request.request_method,
            :url => request.url,
            :env => request.env,
            :params => request.params
        )
        event = Event.new(:name => "Event #{request.path_info}",
                          :payload => payload,
                          :request => req.to_yaml)
        event.save
        limit_events_to limit
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

      ##
      # Read and parse the JSON payload.  This assumes the payload method
      # returns a JSON string.  The output is cached per instance.
      def json
        @json ||= JSON.load(payload)
      end
    end

    helpers AppHelpers


    require 'puppet_labs/pull_request_app/github_auth'
    helpers PuppetLabs::PullRequestApp::GithubAuth

    require 'puppet_labs/pull_request_app/travis_auth'
    helpers PuppetLabs::PullRequestApp::TravisAuth

    configure :production do
      ActiveRecord::Base.logger = logger.clone
      ActiveRecord::Base.logger.level = Logger::ERROR
      Delayed::Backend::ActiveRecord::Job.send(:include, Delayed::Workless::Scaler)
      Delayed::Job.scaler = :heroku_cedar
    end

    configure do
      disable :show_exceptions
      enable :logging
      Delayed::Worker.max_attempts = 5
      Delayed::Worker.max_run_time = 10.minutes
    end

    before '/event/*' do
      event_limit = ENV['STORED_EVENT_LIMIT'] ? ENV['STORED_EVENT_LIMIT'].to_i : 100
      save_event(:request => request, :payload => payload, :limit => event_limit)
      authenticate!
      request.body.rewind
    end

    ##
    # List the last 20 events stored in the database.
    get '/events/?' do
      num = params['num'] ? params['num'].to_i : 20
      body = Event.last(num).collect do |event|
        # See: http://www.sinatrarb.com/intro#Accessing%20the%20Request%20Object
        begin
          req = YAML.load(event.request)
        rescue TypeError => exc
          logger.info "Could not load request from event id #{event.id}"
        end

        entry = Hash.new

        if req
          # Covert the OpenStruct instance into a hash suitable for JSON
          entry['request'] = req.marshal_dump.inject({}) do |memo, (k,v)|
            memo[k.to_s] = v
            memo
          end
        end

        entry['id'] = event.id
        entry['payload'] = JSON.load(event.payload)

        # Return the entry to the collection
        entry
      end
      [200, response_headers, JSON.pretty_generate(body) << "\n"]
    end

    get '/' do
      "Hello World!\n"
    end

    # Previous, but dead, endpoint
    post '/event/pull_request/?' do
      repo = "%s/%s" % [json['repository']['owner_name'],
                        json['repository']['name']]
      log "#{repo} must be reconfigured to use /event/github"
      halt 204, response_headers
    end

    post '/event/travis/?' do
      status = 'Job processing for Travis has not yet been been implemented.'
      log status
      body = { 'status' => status }
      [204, response_headers, JSON.dump(body)]
    end

    post '/event/github/?' do
      payload = payload()

      controller_options = { :route => self, :request => request }
      gh_controller = Github::GithubController.new(controller_options)

      if event_controller = gh_controller.event_controller
        (status_code, headers_hsh, response_body) = event_controller.run
      else
        msg = 'Failed to obtain an event controller.'
        log msg
        halt 204, response_headers, JSON.dump({'status' => msg})
      end

      json_body = JSON.dump(response_body)

      status status_code
      headers headers_hsh.merge(response_headers)
      body json_body
    end
  end
end

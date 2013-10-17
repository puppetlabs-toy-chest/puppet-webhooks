module PuppetLabs
module Github
class Controller
  NO_CONTENT = 204
  ACCEPTED = 202
  OK = 200

  attr_reader :request,
    :route,
    :logger

  # @!attribute [rw] outputs
  #   @return [Array<String>] A list of outputs to use for this controller
  attr_accessor :outputs

  def initialize(options = {})
    @options = options
    if request = options[:request]
      @request = request
    end
    if route = options[:route]
      @route = route
    end
    if logger = options[:logger]
      @logger = logger
    else
      @logger = Logger.new(STDOUT)
    end

    @outputs = default_outputs
  end

  # Generated a new delayed job
  #
  # @param job [Object] An object that implements #perform
  # @param event [Object] The object that is being processed by the job
  #
  # @return [Hash<String, String>] The status of the delayed job
  def enqueue_job(job, event)
    delayed_job = job.queue

    logger.info "Queued #{event.event_description} as job #{delayed_job.id}"

    {
      'status'     => 'ok',
      'job_id'     => delayed_job.id,
      'queue'      => delayed_job.queue,
      'priority'   => delayed_job.priority,
      'created_at' => delayed_job.created_at,
    }
  end

  private

  # Get a list of default environments by checking the environment
  #
  # @param env [Hash] A representation of the environment variables represented
  #   as a hash.
  # @return [Array<String>] A list of the specified outputs
  def default_outputs(env = ENV.to_hash)
    values = (env['GITHUB_EVENT_OUTPUTS'] || 'trello')
    values.split(/,/).map(&:strip)
  end
end
end
end

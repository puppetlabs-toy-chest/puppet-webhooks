module PuppetLabs
module Github
class Controller
  NO_CONTENT = 204
  ACCEPTED = 202
  OK = 200

  attr_reader :request,
    :route,
    :logger

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
  end

  # Generated a new delayed job
  #
  # @param job [Object] An object that implements #perform
  # @param event [Object] The object that is being processed by the job
  #
  # @return [Hash<String, String>] The status of the delayed job
  def enqueue_job(job, event)
    delayed_job = job.queue

    logger.info "Queued #{job.class} (#{event.repo_name}/#{event.number}) as job #{delayed_job.id}"

    {
      'status'     => 'ok',
      'job_id'     => delayed_job.id,
      'queue'      => delayed_job.queue,
      'priority'   => delayed_job.priority,
      'created_at' => delayed_job.created_at,
    }
  end

end
end
end

module PuppetLabs
class Controller
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
end
end

require 'json'

# This class provides a model of a pull rquest.
module PuppetLabs
class PullRequest
  attr_accessor :json
  attr_reader :data
  # Pull request data
  attr_reader :number, :repo_name, :title, :html_url, :body

  def self.from_json(json)
    new(:json => json)
  end

  def initialize(options = {})
    if @json = options[:json]
      load_json
    end
  end

  ##
  # load_json parses the JSON data stored in @json and stores the result in
  # @data
  def load_json
    if data = JSON.load(@json)
      @data = data
      refresh_data
    end
  end

  def refresh_data
    @number = @data['pull_request']['number']
    @title = @data['pull_request']['title']
    @html_url = @data['pull_request']['html_url']
    @body = @data['pull_request']['body']
    @repo_name = @data['repository']['name']
  end
  private :refresh_data
end
end

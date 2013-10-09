module PuppetLabs
module GithubUtils
  ##
  # github_data parses and returns the full object presented in the payload.
  # This is used to de-serialize the payload into a native object.
  #
  # @param [Object] request the request object returned from the Sinatra
  # request method.
  #
  # @return [Object] the deserialized payload
  def github_payload(request)
    JSON.load(request['payload'])
  end
end
end

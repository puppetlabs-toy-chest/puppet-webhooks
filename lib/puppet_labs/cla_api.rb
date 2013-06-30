require 'httparty'

module PuppetLabs
class ClaAPI
  include HTTParty
  class ApiError < StandardError; end
  base_uri 'https://cla.puppetlabs.com/api/v1'

  attr_reader :env

  def initialize(options = {})
    options[:env] ||= ENV.to_hash
    @env = options[:env]
    @auth = {}
    if username = options[:env]['CLA_API_USERNAME']
      @auth[:username] = username
    end
    if password = options[:env]['CLA_API_PASSWORD']
      @auth[:password] = password
    end
  end

  def enabled?
    env['CLA_STATUS_CHECK'] == 'true'
  end

  ##
  # signed_cla_at returns the time a contributor signed the CLA.
  #
  # @param [String] user The user id of the contributor.
  #
  # @api private
  #
  # @return [Time, nil]
  def signed_cla_at(user, options={})
    options.merge!({:basic_auth => @auth})
    options.merge!({:query => {:user => user}})
    response = self.class.get("/signatures.json", options)
    unless response.ok?
      raise ApiError, "CLA API Error: #{[*response['errors']].join(', ')}"
    end
    if time_str = response['signed_cla_at']
      Time.parse(time_str)
    end
  end
end
end

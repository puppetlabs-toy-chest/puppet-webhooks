require 'puppet_labs/cla_api'

module PuppetLabs
module ClaMix
  def cla_api
    @cla_api ||= PuppetLabs::ClaAPI.new(:env => env)
  end

  def cla_enabled?
    cla_api.enabled?
  end

  ##
  # signed_time
  #
  # @param [String] user The user id of the contributor.
  #
  # @return [Time, nil] Time the CLA was signed or nil if not signed
  def signed_time(user)
    cla_api.signed_cla_at(user)
  end
end
end

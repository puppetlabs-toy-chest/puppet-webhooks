require 'puppet_labs/pull_request_app'

require 'digest/sha2'

module PuppetLabs::PullRequestApp::TravisAuth

  ##
  # authenticate_travis returns true if the request is authenticated as a
  # travis request.
  def authenticate_travis(request)
    return false unless json = json()

    if !(secret = ENV['TRAVIS_AUTH_TOKEN'].to_s).empty?
      if repodata = json['repository'] then
        repo = "#{repodata['owner_name']}/#{repodata['name']}"
      else
        return false
      end
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

end

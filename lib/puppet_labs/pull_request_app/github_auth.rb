require 'puppet_labs/pull_request_app'

require 'openssl'
require 'digest/sha2'

module PuppetLabs::PullRequestApp::GithubAuth

  HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

  # Authenticate that a request is valid via X-Hub-Signature
  #
  # TODO: This could be a Sinatra filter.  See:
  # http://sinatra.restafari.org/book.html#authentication
  #
  # @see http://developer.github.com/v3/repos/hooks/#pubsubhubbub
  # @see http://pubsubhubbub.googlecode.com/git/pubsubhubbub-core-0.3.html#authednotify
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
end

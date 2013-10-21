require 'octokit'

module PuppetLabs
  module Github

    # Define a mixin for consumers of the Github API
    module Client

      class EmptyVariableError < StandardError; end

      # Load configuration options for a Github API object from the environment
      def self.client_env_options(env = ENV.to_hash)
        options = {
          :login       => env['GITHUB_ACCOUNT'],
          :password    => env['GITHUB_TOKEN'],
        }

        validate_options!(options)

        options
      end

      # Validate that required configuration options for a Github API object are
      # all present.
      #
      # Note that this forces the application to authenticate against Github,
      # though most most queries can be run without authentication. However
      # unauthenticated accounts only get 60 requests an hour, which is trivial
      # to blow through. For the sake of sanity we require these up front
      # rather than failing later.
      #
      # @see http://developer.github.com/changes/2012-10-14-rate-limit-changes/
      def self.validate_options!(options)
        missing = []

        missing << 'GITHUB_ACCOUNT' unless options[:login]
        missing << 'GITHUB_TOKEN'   unless options[:password]

        if !missing.empty?
          raise EmptyVariableError, "Cannot use Github: missing required environment variables #{missing.join(', ')}"
        end
      end

      attr_writer :client

      def client
        @client ||= Octokit::Client.new(PuppetLabs::Github::Client.client_env_options)
      end
    end
  end
end

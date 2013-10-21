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
      # all present
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

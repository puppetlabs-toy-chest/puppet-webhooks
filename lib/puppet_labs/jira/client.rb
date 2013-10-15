require 'jira'

module PuppetLabs
  module Jira
    module Client

      class EmptyVariableError < StandardError; end

      def self.client_env_options(env = ENV.to_hash)
        options = {
          :username     => env['JIRA_USERNAME'],
          :password     => env['JIRA_PASSWORD'],
          :site         => env['JIRA_SITE'],
          :context_path => env['JIRA_CONTEXT_PATH'],
          :use_ssl      => (env['JIRA_USE_SSL'] == "true"),
          :auth_type    => :basic,
        }

        validate_options!(options)

        options
      end

      def self.validate_options!(options)
        missing = []

        missing << 'JIRA_USERNAME' unless options[:username]
        missing << 'JIRA_PASSWORD' unless options[:password]
        missing << 'JIRA_SITE'     unless options[:site]
        missing << 'JIRA_CONTEXT_PATH' unless options[:context_path]

        if !missing.empty?
          raise EmptyVariableError, "Cannot use JIRA: missing required environment variables #{missing.join(', ')}"
        end
      end

      attr_writer :client

      def client
        @client ||= ::JIRA::Client.new(PuppetLabs::Jira::Client.client_env_options)
      end
    end
  end
end

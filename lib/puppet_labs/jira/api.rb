require 'jira'

module PuppetLabs
  module Jira
    class API

      def self.api
        @api ||= PuppetLabs::Jira::API.from_options(
          :username     => ENV['JIRA_USERNAME'],
          :password     => ENV['JIRA_PASSWORD'],
          :site         => ENV['JIRA_SITE'],
          :context_path => ENV['JIRA_CONTEXT_PATH'],
          :use_ssl      => ENV['JIRA_USE_SSL'],
          :auth_type    => :basic,
        )
      end


      def self.from_options(options)
        client = ::JIRA::Client.new(options)
        new(client)
      end

      attr_reader :client

      def initialize(client)
        @client = client
      end
    end
  end
end

require 'puppet_labs/github/client'

require 'json'

module PuppetLabs
  module Github

    # This represents a github user. Instances of this are generally loaded
    # from events and represent the user that created an event.
    #
    # @see http://developer.github.com/v3/users/
    class User

      include PuppetLabs::Github::Client

      def self.from_json(json)
        user = new
        user.load_json(json)
        user
      end

      def self.from_hash(hash)
        user = new
        user.load_hash(hash)
        user
      end

      # @!attribute [r] raw
      #   @return [Hash] The raw parsed data from the JSON message.
      #   @api private
      attr_reader :raw

      # @!attribute [r] login
      #   @return [String] The login name of the user
      attr_reader :login

      # @!attribute [r] html_url
      #   @return [String] the URL to the user's github page
      attr_reader :html_url

      # @!attribute [r] avatar_url
      #   @return [String] the URL to the user's avatar
      attr_reader :avatar_url

      # @!attribute [r] name
      #   @note this will be fetched from the github API if it is not defined
      #   @return [String] The user's full name
      def name
        @name || fetch!['name']
      end

      # @!attribute [r] company
      #   @note this will be fetched from the github API if it is not defined
      #   @return [String] The user's company
      def company
        @company || fetch!['company']
      end

      # @!attribute [r] email
      #   @note this will be fetched from the github API if it is not defined
      #   @return [String] The user's email address
      def email
        @email || fetch!['email']
      end

      # Parse a JSON string and set the attributes on this object accordingly.
      #
      # @param json [String] The serialized JSON data to parse
      def load_json(json)
        @raw = JSON.load(json)

        load_hash(@raw)
      end

      # Convert a hash representing a deserialized JSON string from Github and
      # set the attributes on this user
      #
      # @param [Hash]
      def load_hash(hash)
        @login      = hash['login']
        @html_url   = hash['html_url']
        @avatar_url = hash['avatar_url']
        @name       = hash['name']
        @company    = hash['company']
        @email      = hash['email']
      end

      private

      # Perform a query for the user so that we can fetch all user attributes
      #
      # @return [Octokit::Response::User]
      def fetch!
        github_user = client.user(login)

        @name    = github_user['name']
        @company = github_user['company']
        @email   = github_user['email']

        github_user
      end
    end
  end
end


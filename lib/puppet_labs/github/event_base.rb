
module PuppetLabs
  module Github

    # Define shared behaviors of Github events
    #
    # @abstract
    #
    # @api private
    class EventBase

      # Generate a object from the JSON representation.
      #
      # @param json [String] The JSON data to turn into an object
      #
      # @return [Object] An instance of the class with the properties set from
      #   the JSON data.
      def self.from_json(json)
        new(:json => json)
      end

      # Generate a new object.
      #
      # @param options [Hash<Symbol, Object>] A hash of named parameters used
      #   for object initialization
      #
      # @option options [String] :json A string containing a JSON representation
      #   of the object
      def initialize(options = {})
        if (json = options[:json])
          load_json(json)
        end
      end

      # @!attribute [r] action
      #   @return [String] The action represented in the event
      attr_reader :action
    end
  end
end

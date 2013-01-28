require 'puppet_labs/trello_api'
require 'puppet_labs/sinatra_dj'
require 'logger'

module PuppetLabs
##
# BaseTrelloJob is responsible for performing the action of updating a Trello
# card based on a bunch of incoming github data.  This data generally comes
# from a webhook event.  This class serves as the base class for subclasses
# that implement behavior specific to certain resources, such as a pull
# request, or an issue.
#
# Subclasses may also override the {#perform} instance method.
#
# Instances of this object are meant to be stored with Delayed Job
class BaseTrelloJob
  include PuppetLabs::SinatraDJ
  attr_reader :list_id, :key, :secret, :token
  attr_writer :env

  ##
  # card_body must be overrided by subclasses.
  #
  # @api public
  def card_body
    raise 'card_body must be overwritten by the child class'
  end

  ##
  # card_body must be overrided by subclasses.
  #
  # @api public
  def card_title
    raise 'card_title must be overwritten by the child class'
  end

  ##
  # card_body must be overrided by subclasses.
  #
  # @api public
  def queue_name
    raise 'queue_name must be ovewritten by the child class'
  end

  ##
  # store_settings copies the TRELLO API information out of the environment and
  # into the instance so it is stored along with the job.  This allows the job
  # to execute in a self contained manner.
  def save_settings
    @list_id = env['TRELLO_TARGET_LIST_ID']
    @key = env['TRELLO_APP_KEY']
    @secret = env['TRELLO_SECRET']
    @token = env['TRELLO_USER_TOKEN']
  end

  ##
  # env is an accessor into the {@env} instance variable.  The current
  # environment is copied to a hash and stored in @env if it does not have a
  # value.
  #
  # @return [Hash] modeling the environment
  def env
    @env ||= ENV.to_hash
  end

  ##
  # perform is the API interface to DelayedJob.  The DJ workers will call the
  # {#perform} method on the instance.  The implementation in the base class
  # creates a trello card using {#create_card}.
  def perform
    name = card_title
    display "Processing: #{name}"
    unless card = find_card(name)
      create_card
    end
    display "Done Processing: #{name}"
  end

  def queue(options={:queue => queue_name})
    queue_job(self, options)
  end

  ##
  # find_card takes a title and locates the card using the Trello API.  If no
  # card exists on the target lists, then nil is returned.
  def find_card(name)
    api = trello_api
    all_cards = api.all_cards_on_board_of(list_id)
    if card = all_cards.find { |card| card.name == name }
      card
    end
  end

  ##
  # create_card creates a card on the target Trello board
  def create_card
    trello = trello_api
    card_options = {
      :name => card_title,
      :list => list_id,
      :description => card_body,
    }
    trello.create_card(card_options)
  end

  def trello_api
    if @trello_api
      return @trello_api
    else
      save_settings
      @trello_api = TrelloAPI.new(key, secret, token)
    end
  end
  private :trello_api

  ##
  # display simply sends text to standard output for use in Heroku.
  def display(text)
    @log ||= Logger.new(STDERR)
    @log.info text
  end
  private :display
end
end

require 'puppet_labs/trello_api'
require 'puppet_labs/sinatra_dj'
require 'logger'
require 'business_time'

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
    if card = find_card(name)
      display "Card #{name} id=#{card.short_id} already exists at url=#{card.url}"
    else
      if card = create_card
        if env['TRELLO_SET_TARGET_RESPONSE_TIME'] == 'true'
          due_date = target_response_time
          card.due = due_date
          display "Set due date of #{name} to #{card.due} url=#{card.url}"
        else
          display "TRELLO_SET_TARGET_RESPONSE_TIME is not 'true' "+
            "not setting card due date for #{name}"
        end
        display "Created card #{name} url=#{card.url}"
        card.save
      else
        display "Did not create card #{name}"
      end
    end
    display "Done Processing: #{name}"
  end

  def queue(options={:queue => queue_name})
    queue_job(self, options)
  end


  ##
  # Methods we discovered:
  # card.delete - deletes the card
  # card.add_comment("Hello"); - adds a comment.
  # card.closed = true; card.save; - Archive a card.
  # card.closed = false; card.save; - Un-archives a card.
  # card.move_to_list(card.board.lists.first); - moves the card to the first
  #   list on the board

  ##
  # find_card takes a title and locates the card using the Trello API.  If no
  # card exists on the target lists, then nil is returned.
  #
  # This method will extract the repository name and pull request number from
  # the name and use the substring as the identifier.  For example, `"(PR
  # puppet-webhooks/18) Add Apache 2.0 License"` will have an identifier of
  # `"(PR puppet-webhooks/18)"`.  This behavior is meant to accomidate renames
  # of the pull request title.
  #
  # If the environment variable TRELLO_BOARDS is set, then the value will be
  # parsed as a comma separated list of Trello board identifiers.  All cards on
  # each board will be searched in addition to the board containing the
  # {list_id}.
  #
  # @return [Trello::Card] or {nil} if no card found.
  def find_card(name)
    api = trello_api
    regexp = %r{\(.*/\d+\)}
    if md = name.match(regexp)
      identifier = md[0]
    else
      identifier = name
    end
    all_cards = api.all_cards_on_board_of(list_id)
    if card = all_cards.find { |card| card.name.include? identifier }
      return card
    end
    if env['TRELLO_BOARDS']
      env['TRELLO_BOARDS'].split(',').each do |board_id|
        cards = api.all_cards_on_board(board_id)
        if card = cards.find { |card| card.name.include? identifier }
          return card
        end
      end
    end
    nil
  end

  ##
  # create_card creates a card on the target Trello board
  def create_card(options = {})
    trello = trello_api
    card_options = {
      :name => card_title,
      :list => list_id,
      :description => card_body,
    }.merge(options)
    trello.create_card(card_options)
  end

  ##
  # target_response_time will return the target due date for a card.  This due
  # date is meant be used as the time that tracks the target response time of
  # the pull request.  This defaults to 5 business hours after the start of the
  # next business day (2 PM).
  #
  # @return [Time] the due date of the card.
  def target_response_time
    now = Time.now
    if Time.before_business_hours?(now)
      next_business_day = now.midnight
    else
      next_business_day = 1.business_day.after(now).midnight
    end
    due_date = 5.business_hour.after(next_business_day)
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

require 'puppet_labs/pull_request'
require 'puppet_labs/sinatra_dj'
require 'logger'
require 'trello'

module PuppetLabs
  ##
  # PullRequestJob is responsible for performing the action of updating a
  # Trello card based on a bunch of Pull Request data.  This data generally
  # comes from a webhook event.
  #
  # Instances of this object are meant to be stored with Delayed Job
class PullRequestJob
  include PuppetLabs::SinatraDJ
  attr_reader :list_id, :key, :secret, :token
  attr_accessor :pull_request
  attr_writer :env

  def card_body
    pr = pull_request
    str = [ "Links: [Pull Request #{pr.number} Discussion](#{pr.html_url}) and",
            "[File Diff](#{pr.html_url}/files)",
            '',
            pr.body,
    ].join("\n")
  end

  def card_title
    pr = pull_request
    "(PR #{pr.repo_name}/#{pr.number}) #{pr.title}"
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

  def env
    @env ||= ENV.to_hash
  end

  ##
  # perform is the API interface to DelayedJob.  The DJ workers will call the
  # `perform` method on the instance.
  def perform
    name = card_title
    display "Processing: #{name}"
    unless card = find_card(name)
      create_card
    end
    display "Done Processing: #{name}"
  end

  def queue(options={:queue => 'pull_request'})
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

class PullRequestClosedJob < PullRequestJob
  def perform
    display "FIXME cannot perform any actions when a pull request is closed"
  end
end

class PullRequestReopenedJob < PullRequestJob
  def perform
    display "FIXME cannot perform any actions when a pull request is reopened"
  end
end

##
# TrelloAPI implements behaviors specific to creating cards on the Puppet
# Community board.  This code is based on the `RMT::Trello` class described at
# [rmt/trello.rb](http://goo.gl/sbd19)
class TrelloAPI
  include ::Trello::Authorization

  def self.config(env=ENV.to_hash)
    env
  end

  # A simple utility function for initializing authentication / authorization
  # for the Trello REST API
  #
  # @param [String] app_key the Trello App Key (can be retrieved from
  # https://trello.com/1/appKey/generate)
  # @param [String] secret the Trello "secret" (can be retrieved from
  # https://trello.com/1/appKey/generate)
  # @param [String] user_token the Trello user token (can be generated with
  # various expiration dates and permissions via instructions at
  # https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
  def initialize(app_key, secret, user_token)
    if ::Trello::Authorization::AuthPolicy != OAuthPolicy
      ::Trello::Authorization.send :remove_const, :AuthPolicy
      ::Trello::Authorization.const_set :AuthPolicy, OAuthPolicy
    end
    # This line is a hack to allow multiple different Trello auths to be used
    # during a single run; the Trello module will cache the consumer otherwise.
    OAuthPolicy.instance_variable_set(:@consumer, nil)

    OAuthPolicy.consumer_credential = OAuthCredential.new(app_key, secret)
    OAuthPolicy.token = OAuthCredential.new(user_token)

    @cards = {}
    @lists = {}
    @boards = {}
  end

  def lists_on_board(board_id)
    ::Trello::Board.find(board_id).lists
  end

  def create_card(properties)
    card = ::Trello::Card.create(:name => properties[:name],
                                 :list_id => properties[:list],
                                 :description => sanitize_utf8(properties[:description]))
    if properties[:color]
      card.add_label(properties[:color])
    end
  end

  def archive_card(card)
    puts "Removing card: #{card.name}"
    card.closed = true
    card.update!
  end

  def list_cards_in(list_id)
    if not @cards[list_id]
      @cards[list_id] = list(list_id).cards
    end
    @cards[list_id]
  end

  def all_cards_on_board_of(list_id)
    board = board_of(list_id)
    if not @cards[board.id]
      @cards[board.id] = board.cards
    end
    @cards[board.id]
  end

  def list(list_id)
    if not @lists[list_id]
      @lists[list_id] = ::Trello::List.find(list_id)
    end
    @lists[list_id]
  end

  def board_of(list_id)
    if not @boards[list_id]
      @boards[list_id] = list(list_id).board
    end
    @boards[list_id]
  end
  private

  def sanitize_utf8(str)
    str.each_char.map { |c| c.valid_encoding? ? c : "\ufffd"}.join
  end
end
end

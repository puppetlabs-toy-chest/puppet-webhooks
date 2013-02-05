require 'trello'

module PuppetLabs
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

  def all_cards_on_board(board_id)
    board = ::Trello::Board.find(board_id)
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

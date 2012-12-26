require 'sinatra'
require 'trello'
require 'json'

get '/' do
  'Hello World'
end

post '/trello/puppet-dev-community/?' do
  gh_data = JSON.load(params['payload'])
  # Configuration
  config = TrelloAPI.config
  app_key = config['TRELLO_APP_KEY']
  secret = config['TRELLO_SECRET']
  user_token = config['TRELLO_USER_TOKEN']
  list_id = config['TRELLO_TARGET_LIST_ID']

  # Data for the card.
  repo_name = gh_data['repository']['name']
  pr_number = gh_data['pull_request']['number']
  pr_title = gh_data['pull_request']['title']

  card_name = "(PR #{repo_name}/#{pr_number}) #{pr_title}"
  card_body = <<-EOBODY
Links: [Pull Request #{gh_data['pull_request']['number']} Discussion](#{gh_data['pull_request']['html_url']}) and
[File Diff](#{gh_data['pull_request']['html_url']}/files)
#{gh_data['pull_request']['body']}
        EOBODY

  trello = TrelloAPI.new(app_key, secret, user_token)
  trello.create_card(
    :name => card_name,
    :list => list_id,
    :description => card_body)

  "Creating card for PR #{gh_data['number']}"
end

##
# TrelloAPI implements behaviors specific to creating cards on the Puppet
# Community board.  This code is based on the {RMT::Trello} class described at
# [rmt/trello.rb](https://github.com/cprice-puppet/redmine-trello/blob/master/lib/rmt/trello.rb)
class TrelloAPI
  include ::Trello::Authorization

  def self.config
    ENV.to_hash
  end

  # A simple utility function for initializing authentication / authorization for the Trello REST API
  #
  # @param [String] the Trello App Key (can be retrieved from https://trello.com/1/appKey/generate)
  # @param [String] the Trello "secret" (can be retrieved from https://trello.com/1/appKey/generate)
  # @param [String] the Trello user token (can be generated with various expiration dates and
  #   permissions via instructions at https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user)
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

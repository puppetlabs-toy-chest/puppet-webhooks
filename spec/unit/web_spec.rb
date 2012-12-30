require 'spec_helper'
require 'web'

# set :environment, :test

# TODO: We're converting from a "Classic" sinatra application to a modular application as per
# http://www.sinatrarb.com/extensions.html  These behaviors should actually be implemented against
# PuppetLabs::PullRequestApp which descends from Sinatra::Base

describe 'The App' do
  include WebHook::Test::Methods
  include Rack::Test::Methods

  before :each do
    Trello::Card.stub(:create)
  end

  def app
    Sinatra::Application
  end

  def env_vars
    @env_vars ||= %w{TRELLO_APP_KEY TRELLO_SECRET TRELLO_USER_TOKEN TRELLO_TARGET_LIST_ID}
  end

  let :gh_data do
    JSON.load(params['payload'])
  end

  let :params do
    { 'payload' => read_fixture("example_pull_request.json") }
  end

  xit "says hello" do
    get "/"
    last_response.should be_ok
    last_response.body.should == 'Hello World'
  end

  context 'posting a pull request' do
    let :to_endpoint do
      "/event/pull_request"
    end

    xit 'delegates to to' do

      post to_endpoint, params
      last_response.should be_ok
    end
  end

  context  'runs when a pull request is opened' do
    let :to_endpoint do
      "/trello/puppet-dev-community"
    end

    describe 'response' do
      xit 'is OK' do
        post to_endpoint, params
        last_response.should be_ok
      end

      xit 'has a body mentioning the PR number' do
        post to_endpoint, params
        last_response.body.should == "Creating card for PR #{gh_data['number']}"
      end
    end
    describe 'the hook' do
      before :each do
        TrelloAPI.stub(:config) { Hash.new('test_value') }
      end


      xit 'obtains the config object' do
        TrelloAPI.should_receive(:config)

        post to_endpoint, params
      end

      xit 'creates a card on the target list with a specific format' do
        TrelloAPI.stub(:config) do
          hsh = Hash.new('test_value')
          hsh['TRELLO_TARGET_LIST_ID'] = 'the_list_identifier'
          hsh
        end

        trello_double = double(TrelloAPI)
        TrelloAPI.should_receive(:new) { trello_double }

        trello_double.should_receive(:create_card).with do |properties|
          pr = gh_data['pull_request']
          repo = gh_data['repository']
          properties[:name].should == "(PR #{repo['name']}/#{pr['number']}) #{pr['title']}"
          properties[:list].should == 'the_list_identifier'
          properties[:description].should == expected_pr_body
        end

        post to_endpoint, params
      end
    end
  end
end

require 'puppet_labs/trello_utils'

describe 'Trello Utils' do
  subject do
    PuppetLabs::TrelloUtils
  end

  it 'is a mixable module so it can be a Sinatra helper' do
    subject.should be_a Module
  end

end

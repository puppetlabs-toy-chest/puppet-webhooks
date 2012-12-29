require 'spec_helper'
require 'web'

set :environment, :test

describe 'The App' do
  include Rack::Test::Methods

  before :each do
    Trello::Card.stub(:create)
  end

  def app
    Sinatra::Application
  end

  it "says hello" do
    get "/"
    last_response.should be_ok
    last_response.body.should == 'Hello World'
  end

  def read_fixture(name)
    File.read(File.join(File.expand_path("..", __FILE__), "fixtures", name))
  end

  context  'runs when a pull request is opened' do
    def env_vars
      @env_vars ||= %w{TRELLO_APP_KEY TRELLO_SECRET TRELLO_USER_TOKEN TRELLO_TARGET_LIST_ID}
    end

    let :to_endpoint do
      "/trello/puppet-dev-community"
    end

    let :gh_data do
      JSON.load(params['payload'])
    end

    let :params do
      { 'payload' => read_fixture("example_pull_request.json") }
    end

    describe 'response' do
      let :params do
        { 'payload' => read_fixture("example_pull_request.json") }
      end

      it 'is OK' do
        post to_endpoint, params
        last_response.should be_ok
      end

      it 'has a body mentioning the PR number' do
        post to_endpoint, params
        last_response.body.should == "Creating card for PR #{gh_data['number']}"
      end
    end
    describe 'the hook' do
      before :each do
        TrelloAPI.stub(:config) { Hash.new('test_value') }
      end

      let :expected_pr_body do
        str = <<-EOBODY
Links: [Pull Request #{gh_data['pull_request']['number']} Discussion](#{gh_data['pull_request']['html_url']}) and
[File Diff](#{gh_data['pull_request']['html_url']}/files)
#{gh_data['pull_request']['body']}
        EOBODY
      end

      it 'obtains the config object' do
        TrelloAPI.should_receive(:config)

        post to_endpoint, params
      end

      it 'creates a card on the target list with a specific format' do
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

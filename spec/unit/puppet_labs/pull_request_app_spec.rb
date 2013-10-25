require 'spec_helper'
require 'ostruct'
require 'puppet_labs/pull_request_app'

describe 'PuppetLabs::PullRequestApp' do
  include Rack::Test::Methods

  def app
    PuppetLabs::PullRequestApp
  end

  attr_reader :payload,
    :params,
    :env,
    :payload_closed,
    :payload_synchronize

  before :each do
    PuppetLabs::PullRequestApp.any_instance.stub(:authenticate!)

    PuppetLabs::Github::Controller.any_instance.stub(:logger).and_return(double.as_null_object)
    app.any_instance.stub(:logger).and_return(double.as_null_object)
  end

  it 'says hello' do
    get '/'
    last_response.should be_ok
    last_response.body.should == "Hello World!\n"
  end

  context 'posting an issue' do
    before :all do
      @payload = read_fixture("example_issue.json")
      @payload_closed = read_fixture("example_issue_closed.json")
      @params = { 'payload' => @payload }
      @env = { 'HTTP_X_GITHUB_EVENT' => 'issues' }
    end

    let (:route) { '/event/github' }
    let (:job) { PuppetLabs::Trello::TrelloIssueJob.new }

    describe '/event/github' do
      it "responds to /event/github" do
        post route, params, env
        last_response.should have_status 202
      end
    end
  end

  context 'posting a pull request' do
    before :all do
      @payload = read_fixture("example_pull_request.json")
      @payload_closed = read_fixture("example_pull_request_closed.json")
      @payload_synchronize = read_fixture("example_pull_request_synchronize.json")
      @params = { 'payload' => @payload }
      @env = { 'HTTP_X_GITHUB_EVENT' => 'pull_request' }
    end

    let (:route) { '/event/github' }
    let (:job) { PuppetLabs::Trello::TrelloPullRequestJob.new }

    describe '/event/github' do
      it "responds to /event/github" do
        post route, params, env
        last_response.should have_status 202
      end

      it "saves the event" do
        PuppetLabs::PullRequestApp.any_instance.should_receive(:save_event)
        post route, params, env
        last_response.should have_status 202
      end

      it "saves the event based on STORED_EVENT_LIMIT ENV variable" do
        PuppetLabs::PullRequestApp.any_instance.should_receive(:save_event).with() do |hsh|
          hsh[:limit] == 100
        end
        post route, params, env
      end

      it "saves the event based on STORED_EVENT_LIMIT ENV variable" do
        PuppetLabs::PullRequestApp.any_instance.should_receive(:save_event).with() do |hsh|
          hsh[:limit] == 200
        end
        env_saved = ENV['STORED_EVENT_LIMIT']
        ENV['STORED_EVENT_LIMIT'] = '200'
        post route, params, env
        ENV['STORED_EVENT_LIMIT'] = env_saved
      end

      it "sets the content-type to application/json" do
        post route, params, env
        last_response.headers['Content-Type'].should == 'application/json'
      end

      context 'posting a closed pull request' do
        let (:params) { { 'payload' => payload_closed } }

        before :each do
          fake_job = job
          pr_model = PuppetLabs::Github::PullRequest.new(:json => payload_closed)
          PuppetLabs::Github::PullRequest.stub(:from_json).with(payload_closed).and_return(pr_model)
          PuppetLabs::Trello::TrelloPullRequestJob.stub(:new).and_return(fake_job)
        end

        it "responds with 202" do
          post route, params, env
          last_response.should have_status 202
        end
      end
    end
  end
end

describe PuppetLabs::PullRequestApp::AppHelpers do
  before :all do
    @req_yaml = read_fixture("request_struct.yml")
  end
  class TestHelpers
    include PuppetLabs::PullRequestApp::AppHelpers
  end
  subject do
    TestHelpers.new
  end
  def request
    @request ||= YAML.load(@req_yaml)
  end

  describe '.save_event' do
    [20, 30, 40].each do |event_limit|
      it "limits the number of events to #{event_limit}" do
        subject.should_receive(:limit_events_to).with(event_limit)
        subject.save_event(:request => request, :limit => event_limit)
      end
    end
  end

  describe '.limit_events_to' do
    after :each do
      PuppetLabs::Event.delete_all
    end
    event_limit = 20
    event_count = 30
    it "keeps the most recent #{event_limit} events when there are #{event_count}" do
      event_count.times do
        PuppetLabs::Event.new.save
      end
      expected = PuppetLabs::Event.order("id desc").limit(event_limit).collect do |ev|
        ev.id
      end
      subject.limit_events_to(event_limit)
      actual = PuppetLabs::Event.order("id desc").collect {|ev| ev.id }
      actual.should == expected
    end
  end
end
